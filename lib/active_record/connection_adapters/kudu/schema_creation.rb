# frozen_string_literal: true

require 'active_record/connection_adapters/abstract/schema_creation'

module ActiveRecord
  module ConnectionAdapters
    module Kudu
      class SchemaCreation < ::ActiveRecord::ConnectionAdapters::AbstractAdapter::SchemaCreation

        private

        def visit_ColumnDefinition(obj)
          obj.sql_type = type_to_sql(obj.type, obj.options)
          column_sql = "#{quote_column_name(obj.name)} #{obj.sql_type}".dup
          add_column_options!(column_sql, column_options(obj))
        end

        # @param table_def [::ActiveRecord::ConnectionAdapters::Kudu::TableDefinition]
        def visit_TableDefinition(table_def)
          create_sql = "CREATE#{' EXTERNAL' if table_def.external} TABLE #{quote_table_name(table_def.name)} "

          statements = table_def.columns.map { |col| accept col }

          primary_keys = if table_def.primary_keys&.any?
                           table_def.primary_keys
                         else
                           table_def.columns.select { |col| col.options[:primary_key] }.map(&:name)
                         end

          raise "Table #{table_def.name} does not have primary key(s) defined" if primary_keys.empty?
          quoted_names = primary_keys.map { |pk| quote_column_name(pk) }

          statements << "PRIMARY KEY (#{quoted_names.join(', ')})"

          create_sql += "(#{statements.join(', ')})" if statements.present?
          add_table_options!(create_sql, table_options(table_def))

          # For managed Kudu tables partitioning must be defined
          unless table_def.external
            # If no partition columns will be provided, we will use all primary keys defined
            partition_columns = table_def.partition_columns || primary_keys
            if (partition_columns - table_def.columns.map(&:name)).any?
              raise 'Non-existing columns have been selected as partition indicators'
            end

            partitions_count = table_def.partitions_count || 2
            quoted_names = partition_columns.map { |pc| quote_column_name(pc) }
            create_sql += " PARTITION BY HASH(#{quoted_names.join(', ')}) PARTITIONS #{partitions_count.to_i}"
            # TODO: partitions range
          end

          create_sql + ' STORED AS KUDU'
        end

        def add_column_options!(sql, options)
          sql += options[:null] ? ' NULL' : ' NOT NULL'

          sql += " ENCODING #{quote_default_expression(options[:encoding])}" if options[:encoding]
          sql += " COMPRSESSION #{quote_default_expression(options[:compression])}" if options[:compression]
          sql += " DEFAULT #{quote_default_expression(options[:default])}" if options[:default]
          sql += " BLOCK SIZE #{options[:block_size].to_i}" if options[:block_size]
          sql
        end

      end
    end
  end
end
