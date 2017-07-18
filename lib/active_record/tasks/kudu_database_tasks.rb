# frozen_string_literal: true

require 'active_record/tasks/database_tasks'

module ActiveRecord
  # :nodoc:
  module Tasks
    # :nodoc:
    class KuduDatabaseTasks
      delegate :connection, :establish_connection, :clear_active_connections!,
               to: ::ActiveRecord::Base

      # @!attribute [r] configuration
      #  @return [Hash] Database configuration
      attr_reader :configuration

      def initialize(configuration)
        @configuration = configuration
      end

      def create
        establish_connection
        connection.create_database configuration['database']
      end
    end

    DatabaseTasks.register_task /kudu/, KuduDatabaseTasks
  end
end
