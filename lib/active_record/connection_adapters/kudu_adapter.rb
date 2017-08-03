# frozen_string_literal: true

require 'active_record/connection_adapters/kudu/database_statements'
require 'active_record/connection_adapters/kudu/schema_statements'
require 'active_record/connection_adapters/kudu/type/big_int'
require 'active_record/connection_adapters/kudu/type/boolean'
require 'active_record/connection_adapters/kudu/type/char'
require 'active_record/connection_adapters/kudu/type/date_time'
require 'active_record/connection_adapters/kudu/type/double'
require 'active_record/connection_adapters/kudu/type/float'
require 'active_record/connection_adapters/kudu/type/integer'
require 'active_record/connection_adapters/kudu/type/small_int'
require 'active_record/connection_adapters/kudu/type/string'
require 'active_record/connection_adapters/kudu/type/time'
require 'active_record/connection_adapters/kudu/type/tiny_int'
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
  module Timestamp
    private
    def _create_record
      if record_timestamps
        current_time = current_time_from_proper_timezone
        all_timestamp_attributes_in_model.each do |column|
          # force inserting of current time for timestamp columns if is needed
          write_attribute(column, current_time)
        end
      end
      super
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

      def lookup_cast_type_from_column(column)
        lookup_cast_type column.type.to_s
      end

      def quote_table_name(table_name)
        table_name # TODO
      end

      def quoted_true
        true.to_s
      end

      def unquoted_true
        true
      end

      def quoted_false
        false.to_s
      end

      def unquoted_false
        false
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

      def initialize_type_map(mapping)
        mapping.register_type(/bigint/i, ::ActiveRecord::ConnectionAdapters::Kudu::Type::BigInt.new)
        mapping.register_type(/boolean/i, ::ActiveRecord::ConnectionAdapters::Kudu::Type::Boolean.new)
        mapping.register_type(/char/i, ::ActiveRecord::ConnectionAdapters::Kudu::Type::Char.new)
        mapping.register_type(/datetime/i, ::ActiveRecord::ConnectionAdapters::Kudu::Type::DateTime.new)
        mapping.register_type(/double/i, ::ActiveRecord::ConnectionAdapters::Kudu::Type::Double.new)
        mapping.register_type(/float/i, ::ActiveRecord::ConnectionAdapters::Kudu::Type::Float.new)
        mapping.register_type(/integer/i, ::ActiveRecord::ConnectionAdapters::Kudu::Type::Integer.new)
        mapping.register_type(/smallint/i, ::ActiveRecord::ConnectionAdapters::Kudu::Type::SmallInt.new)
        mapping.register_type(/string/i, ::ActiveRecord::ConnectionAdapters::Kudu::Type::String.new)
        mapping.register_type(/(date){0}time/i, ::ActiveRecord::ConnectionAdapters::Kudu::Type::Time.new)
        mapping.register_type(/tinyint/i, ::ActiveRecord::ConnectionAdapters::Kudu::Type::TinyInt.new)
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
