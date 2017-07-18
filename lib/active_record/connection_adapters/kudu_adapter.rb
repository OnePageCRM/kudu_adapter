# frozen_string_literal: true

require 'active_record/connection_adapters/kudu/schema_statements'
require 'impala'
require 'kudu_adapter/bind_substitution'

module ActiveRecord
  # Create new connection with Impala database
  # @param config [::Hash] Connection configuration options
  class Base
    def self.kudu_connection(config)
      ::ActiveRecord::ConnectionAdapters::KuduAdapter.new(nil, logger, config)
    end
  end

  # :nodoc:
  module ConnectionAdapters
    # Main Impala connection adapter class
    class KuduAdapter < ::ActiveRecord::ConnectionAdapters::AbstractAdapter

      include Kudu::SchemaStatements

      ADAPTER_NAME = 'Kudu'

      # @!attribute [r] connection
      #  @return [::Impala::Connection] Connection which we are working on
      attr_reader :connection

      NATIVE_DATABASE_TYPES = {
        tinyint: { name: 'tinyint' }, # 1 byte
        smallint: { name: 'smallint' }, # 2 bytes
        integer: { name: 'int' }, # 4 bytes
        bigint: { name: 'bigint' }, # 8 bytes
        decimal: { name: 'decimal' }, # TODO precision (1-38), scale
        float: { name: 'float' },
        double: { name: 'double' },
        boolean: { name: 'boolean' },
        char: { name: 'char', limit: 255 },
        string: { name: 'string' }, # 32767 characters
        varchar: { name: 'varchar', limit: 65_535 },
        time: { name: 'timestamp' }
      }.freeze

      def initialize(connection, logger, connection_params)
        super(connection, logger)

        @connection_params = connection_params
        connect
        @visitor = ::KuduAdapter::BindSubstition.new self
      end

      def connect
        @connection = ::Impala.connect(
          @connection_params[:host],
          @connection_params[:port]
        )
      end

      def disconnect!
        @connection.close
        @connection = nil
      end

      def reconnect!
        disconnect!
        connect
      end

      def active?
        @connection.execute('SELECT now()')
        true
      rescue
        false
      end

      def execute(sql, name = nil)
        with_auto_reconnect do
          log(sql, name) { @connection.execute(sql) }
        end
      end

      def query(sql, name = nil)
        with_auto_reconnect do
          log(sql, name) do
            @connection.query sql
          end
        end
      end

      def supports_migrations?
        true
      end

      def supports_primary_key?
        true
      end

      def native_database_types
        ::ActiveRecord::ConnectionAdapters::KuduAdapter::NATIVE_DATABASE_TYPES
      end

      def with_auto_reconnect
        yield
      rescue Thrift::TransportException => e
        raise unless e.message == 'end of file reached'
        reconnect!
        yield
      end

      def create_database(database_name)
        # TODO: escape name
        execute "CREATE DATABASE IF NOT EXISTS `#{database_name}`"
      end
    end
  end
end
