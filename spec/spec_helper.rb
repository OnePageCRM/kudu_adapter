# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'rubygems'
require 'bundler'
require 'yaml'

Bundler.setup :default, :development

$LOAD_PATH.unshift(File.expand('../../lib', __FILE__))

# Load config, if present
config_path = File.expand('../spec_config.yaml', __FILE__)
config = if File.exist?(config_path)
           puts "==> Loading config from #{config_path}"
           YAML.load_file config_path
         else
           puts '==> Loading config from env or use default'
           {
             'database' => {}
           }
         end

require 'rspec'

require 'active_record'

require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/class/attribute_accessors'

require 'active_support/log_subscriber'
require 'active_record/log_subscriber'

require 'logger'

require 'active_record/connection_adapters/kudu_adapter'

puts "==> Effective ActiveRecord version #{ActiveRecord::VERSION::STRING}"

# :nodoc:
module LoggerSpecHelper
  def set_logger
    @logger = MockLogger.new
    @old_logger = ActiveRecord::Base.logger

    @notifier = ActiveSupport::Notifications::Fanout.new

    ActiveSupport::LogSubscriber.colorize_logging = false

    ActiveRecord::Base.logger = @logger

    @old_notifier = ActiveSupport::Notifications.notifier
    ActiveSupport::Notifications.notifier = @notifier

    ActiveRecord::LogSubscriber.attach_to :active_record
    ActiveSupport::Notifications.subscribe 'sql.active_record',
                                           ActiveRecord::ExplainSubscriber.new
  end

  # :nodoc:
  class MockLogger
    attr_reader :flush_count

    def initialize
      @flush_count = 0
      @logged = Hash.new { |h, k| h[k] = [] }
    end

    def method_missing(level, message)
      if respond_to_missing?(level)
        @logged[level] << message
      else
        super
      end
    end

    def respond_to_missing?(method, *)
      %i[debug info warn error].include?(method) || super
    end

    def logged(level)
      @logged[level].compact.map { |l| l.to_s.strip }
    end

    def output(level)
      logged(level).join "\n"
    end

    def flush
      @flush_count += 1
    end

    def clear(level)
      @logged[level] = []
    end
  end
end

DATABASE_NAME = config['database']['name'] ||
                ENV['DATABASE_NAME'] ||
                'test'
DATABASE_HOST = config['database']['host'] ||
                ENV['DATABASE_HOST'] ||
                '127.0.0.1'
DATABASE_PORT = config['database']['port'] ||
                ENV['DATABASE_PORT'] ||
                28_050
DATABASE_USER = config['database']['user'] ||
                ENV['DATABASE_USER'] ||
                'kudu'
DATABASE_PASSWORD = config['database']['password'] ||
                    ENV['DATABASE_PASSWORD'] ||
                    'impala'

CONNECTION_PARAMS = {
  adapter: 'kudu',
  database: DATABASE_NAME,
  host: DATABASE_HOST,
  port: DATABASE_PORT,
  username: DATABASE_USER,
  password: DATABASE_PASSWORD
}.freeze
