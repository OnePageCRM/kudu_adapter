# frozen_string_literal: true

require 'active_record/connection_adapters/kudu/database_statements'
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

      include Kudu::DatabaseStatements
      include Kudu::SchemaStatements

      ADAPTER_NAME = 'Kudu'

      # @!attribute [r] connection
      #  @return [::Impala::Connection] Connection which we are working on
      attr_reader :connection

      NATIVE_DATABASE_TYPES = {
        primary_key: { name: 'INT' },
        tinyint: { name: 'TINYINT' }, # 1 byte
        smallint: { name: 'SMALLINT' }, # 2 bytes
        integer: { name: 'INT' }, # 4 bytes
        bigint: { name: 'BIGINT' }, # 8 bytes
        float: { name: 'FLOAT' },
        double: { name: 'DOUBLE' },
        boolean: { name: 'BOOLEAN' },
        char: { name: 'CHAR', limit: 255 },
        string: { name: 'STRING' }, # 32767 characters
        time: { name: 'BIGINT' },
        datetime: { name: 'BIGINT' }
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

        db_names = @connection.query('SHOW DATABASES').map {|db| db[:name]}

        @connection.execute('USE ' + @connection_params[:database]) if
          @connection_params[:database].present? && db_names.include?(@connection_params[:database])
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

      def quote_table_name(table_name)
        table_name # TODO
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
