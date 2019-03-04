# frozen_string_literal: true

require 'spec_helper'

describe ActiveRecordQueryTrace do
  let(:logger_io) { StringIO.new }
  let(:logger) { Logger.new(logger_io) }
  let(:log) { logger_io.string }
  let(:log_subscriber) do
    ActiveRecord::LogSubscriber.log_subscribers
      .find { |ls| ls.class == ActiveRecordQueryTrace::CustomLogSubscriber }
  end

  before do
    # If level is set to :app, the backtrace will be empty as there is no Rails
    # application running in the gem test environment.
    described_class.level = :full
    described_class.enabled = true
    ActiveRecord::Base.logger = logger
  end

  # Clean log after each example
  after { logger_io.truncate(0) }

  describe 'configuration options' do
    describe '.enabled' do
      it 'is disabled by default' do
        # The first before block of this spec sets `enabled` to `true`. Here we
        # call initialize to reset to the default value.
        described_class::CustomLogSubscriber.new
        expect(described_class.enabled).to eq(false)
      end

      context 'when enabled' do
        before { described_class.enabled = true }

        # TODO: improve this. Currently, it will pass if the prefix is there but the backtrace is not.
        it 'adds backtrace to the log' do
          User.create!
          expect(log).to match(described_class::BACKTRACE_PREFIX)
        end
      end

      context 'when disabled' do
        before { described_class.enabled = false }

        it 'does not add backtrace to the log' do
          User.create!
          expect(log).not_to match(described_class::BACKTRACE_PREFIX)
        end
      end
    end

    describe '.level' do
      let(:app_frames) do
        [
          "/projects/my_rails_project/app/controllers/users_controller.rb:10:in `index'",
          "/projects/my_rails_project/lib/foo.rb:10:in `bar'"
        ]
      end
      let(:rails_frames) do
        [
          "/home/username/.rvm/gems/ruby-2.5.3/gems/actionpack-5.2.1.1/lib/action_controller/metal/foo.rb:6:in `bar'",
          "/home/username/.rvm/gems/ruby-2.5.3/gems/activesupport-5.2.2/lib/active_support/subscriber.rb:101:in `foo'",
          "/home/username/.rvm/gems/ruby-2.5.3/gems/puma-3.12.0/lib/puma/server.rb:332:in `block in run'"
        ]
      end

      before do
        # Reset to the default filters and silencers set by Rails' backtrace cleaner.
        Rails.instance_variable_set(:@backtrace_cleaner, Rails::BacktraceCleaner.new)
        # The first before block of this spec sets level to :full. Here we call
        # initialize to reset to the default level.l
        described_class::CustomLogSubscriber.new
        described_class.enabled = true
        allow(log_subscriber).to receive(:original_trace).and_return(app_frames + rails_frames)
      end

      it 'is set to :app by default' do
        expect(described_class.level).to eq(:app)
      end

      context 'when set to :full' do
        before do
          described_class.level = :full
          User.create!
        end

        it 'displays all backtrace frames' do
          expect(log).to match(
            /
              .*#{Regexp.escape(described_class::BACKTRACE_PREFIX)}
              #{Regexp.escape((app_frames + rails_frames).join("\n" + described_class::INDENTATION))}
            /x
          )
        end
      end

      context 'when set to :rails' do
        before do
          described_class.level = :rails
          User.create!
        end

        it 'only displays framework backtrace frames' do
          expect(log).to match(
            /
              .*
              #{Regexp.escape(described_class::BACKTRACE_PREFIX)}
              #{Regexp.escape(rails_frames.join("\n" + described_class::INDENTATION))}
            /x
          )
        end
      end

      context 'when set to :app' do
        before do
          described_class.level = :app
          User.create!
        end

        # The default settings of Rails' backtrace cleaner replaces full paths
        # in the backtrace with relative paths.
        let(:app_frames_with_relative_path) { app_frames.map { |f| f.gsub("#{Rails.root}/", '') } }

        it 'only displays application backtrace frames' do
          expect(log).to match(
            /
              .*
              #{Regexp.escape(described_class::BACKTRACE_PREFIX)}
              #{Regexp.escape(app_frames_with_relative_path.join("\n" + described_class::INDENTATION))}
            /x
          )
        end
      end
    end

    describe '.lines' do
      let(:frame) { "/projects/my_rails_project/app/controllers/users_controller.rb:10:in `index'" }
      let(:bakctrace) { Array.new(30, frame) }

      before do
        described_class.enabled = true
        allow(log_subscriber).to receive(:original_trace).and_return(bakctrace)
      end

      it 'is set to 5 by default' do
        # Call initialize to reset to the default value.
        described_class::CustomLogSubscriber.new
        expect(described_class.lines).to eq(5)
      end

      [1, 5, 10, 20, 30].each do |lines|
        context "when set to #{lines}" do
          before do
            described_class.lines = lines
            User.create!
          end

          it "displays the last #{lines} #{'line'.pluralize(lines)} of the backlog" do
            expect(log.scan(frame).size).to eq(lines)
          end
        end
      end
    end

    describe '.ignore_cached_queries' do
      before { described_class.enabled = true }

      it 'is disabled by default' do
        # Call initialize to reset to the default value.
        described_class::CustomLogSubscriber.new
        expect(described_class.ignore_cached_queries).to eq(false)
      end

      context 'when set to true' do
        before do
          described_class.ignore_cached_queries = true
          # The second call to User.all.load will hit the cache
          ActiveRecord::Base.cache { 2.times { User.all.load } }
        end

        it 'does not display the backtrace for cached queries' do
          expect(log).not_to match(/CACHE User Load.*#{described_class::BACKTRACE_PREFIX}/m)
        end
      end

      context 'when set to false' do
        before do
          described_class.ignore_cached_queries = false
          # The second call to User.all.load will hit the cache
          ActiveRecord::Base.cache { 2.times { User.all.load } }
        end

        it 'displays the backtrace for cached queries' do
          expect(log).to match(/CACHE.*#{described_class::BACKTRACE_PREFIX}/m)
        end
      end
    end

    describe '.colorize' do
      it 'is disabled by default' do
        # Call initialize to reset to the default value.
        described_class::CustomLogSubscriber.new
        expect(described_class.colorize).to eq(false)
      end

      described_class::COLORS.except(true).each do |color_name, color_code|
        context "When ActiveRecordQueryTrace.colorize is set to #{color_name.to_s.humanize.downcase}" do
          let(:regexp) do
            /
              \e\[#{color_code}m                                    # Start colorizing with the selected color
              #{Regexp.escape(described_class::BACKTRACE_PREFIX)}   # The backtrace prefix (e.g., Query Trace:)
              .*                                                    # The actual backtrace
              \e\[0m                                                # Reset to the default color
            /xm
          end

          context 'with a symbol as the color name and underscore as word separator' do
            before do
              described_class.colorize = color_name
              User.create!
            end

            it 'displays the backtrace with the selected color then resets to the default color' do
              expect(log).to match(regexp)
            end
          end

          context 'with a string as the color name and space as word separator' do
            before do
              described_class.colorize = color_name.to_s.tr('_', "\s") # e.g., 'light purple'
              User.create!
            end

            it 'displays the backtrace with the selected color then resets to the default color' do
              expect(log).to match(regexp)
            end
          end
        end
      end
    end
  end
end
