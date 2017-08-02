# frozen_string_literal: true

require 'active_record/connection_adapters/kudu/column'
require 'active_record/connection_adapters/kudu/schema_creation'
require 'active_record/connection_adapters/kudu/sql_type_metadata'
require 'active_record/connection_adapters/kudu/table_definition'
require 'active_record/migration/join_table'

# :nodoc:
module ActiveRecord
  module ConnectionAdapters
    module Kudu
      include ::ActiveRecord::Migration::JoinTable

      # TODO methods delegate :quote_column_name, :quote_default_expression, :type_to_sql,
      # :options_include_default?, :supports_indexes_in_create?, :supports_foreign_keys_in_create?,
      # :foreign_key_options, to: :@conn
      # ^^^ THOSE ARE FROM SCHEMACREATION ^^^

      # :nodoc:
      module SchemaStatements
        def table_options(table_name)
          nil # TODO???
        end

        def table_comment(table_name)
          raise 'TODO: Implement me (table comment)'
        end

        def table_alias_for(table_name)
          table_name.tr('.', '_')
        end

        def data_sources
          tables | views
        end

        def data_source_exists?(name)
          data_sources.include? name.to_s
        end

        def tables
          connection.query('SHOW TABLES').map { |table| table[:name] }
        end

        def table_exists?(table_name)
          tables.include? table_name.to_s
        end

        # Return list of existing views. As we are not supporting them,
        # this list will be always empty
        def views
          []
        end

        # Check if given view exists. As we are not supporting views,
        # it'll be always false
        def view_exists?(_)
          false
        end

        def indexes(table_name, name = nil)
          [] # TODO? Or mark as not implemented
        end

        def index_exists?(table_name, column_name, options = {})
          raise 'TODO: Implement me (index exists?)'
        end

        def columns(table_name)
          table_structure(table_name).map do |col_def|
            type = if col_def[:type] == 'int'
                     :integer
                   elsif col_def[:type] == 'bigint' && /_at$/ =~ col_def[:name]
                     :datetime
                   else
                     col_def[:type].to_sym
                   end
            stm = ::ActiveRecord::ConnectionAdapters::Kudu::SqlTypeMetadata.new(sql_type: col_def[:type], type: type)
            ::ActiveRecord::ConnectionAdapters::Kudu::Column.new(
              col_def[:name],
              col_def[:default_value]&.empty? ? nil : col_def[:default_value],
              stm,
              col_def[:null] == 'true',
              table_name,
              col_def[:comment]
            )
          end
        end

        def column_exists?(table_name, column_name, type = nil, options = {})
          column_name = column_name.to_s
          checks = []
          checks << lambda { |c| c.name == column_name }
          checks << lambda { |c| c.type == type } if type
          column_options_keys.each do |attr|
            checks << lambda { |c| c.send(attr) == options[attr] } if options.key?(attr)
          end
          columns(table_name).any? { |c| checks.all? { |check| check[c] } }
        end

        def primary_key(table_name)
          pks = table_structure(table_name).select { |col| col[:primary_key] == 'true' }
          pks.map! { |pk| pk[:name] }
          pks.size == 1 ? pks.first : pks
        end

        def create_table(table_name, comment: nil, **options)
          td = create_table_definition table_name, options[:temporary], options[:options], options[:as], comment: comment
          if options[:id] != false && !options[:as]
            pk = options.fetch(:primary_key) do
              Base.get_primary_key table_name.to_s.singularize
            end

            if pk.is_a?(Array)
              td.primary_keys pk
            else
              td.primary_key pk, options.fetch(:id, :primary_key), options
            end
          end

          yield td if block_given?

          options[:force] && drop_table(table_name, **options, if_exists: true)

          result = execute schema_creation.accept td

          unless supports_indexes_in_create?
            td.indexes.each do |column_name, index_options|
              add_index(table_name, column_name, index_options)
            end
          end

          if supports_comments? && !supports_comments_in_create?
            change_table_comment(table_name, comment) if comment.present?
            td.columns.each do |column|
              change_column_comment(table_name, column.name, column.comment) if column.comment.present?
            end
          end

          result
        end

        def drop_table(table_name, **options)
          execute "DROP TABLE#{' IF EXISTS' if options[:if_exists]} #{quote_table_name(table_name)}"
        end

        def create_join_table(table_1, table_2, colum_options: {}, **options)
          raise 'TODO: Implement me (create join table)'
        end

        def drop_join_table(table_1, table_2, options = {})
          raise 'TODO: Implement me (drop join table)'
        end

        def change_table(table_name, options = {})
          raise 'TODO: Implement me (change table)'
        end

        def rename_table(table_name, new_name)
          execute "ALTER TABLE #{quote_table_name(table_name)} RENAME TO #{quote_table_name(new_name)}"
        end

        def add_column(table_name, column_name, type, options = {})
          at = create_alter_table table_name
          at.add_column(column_name, type, options)
          execute schema_creation.accept at
        end

        def remove_columns(table_name, column_names)
          raise ArgumentError.new("You must specify at least one column name. Example: remove_columns(:people, :first_name)") if column_names.empty?
          column_names.each do |column_name|
            remove_column(table_name, column_name)
          end
        end

        def remove_column(table_name, column_name, type = nil, options = {})
          execute "ALTER TABLE #{quote_table_name(table_name)} DROP COLUMN #{quote_column_name(column_name)}"
        end

        def change_column(table_name, type, options)
          raise 'TODO: Implement me (change column)'
        end

        def change_column_default(table_name, column_name, default_or_changes)
          raise 'TODO: Implement me (change column default)'
        end

        def change_column_null(table_name, column_name, null, default = nil)
          raise 'TODO: Implement me (change column null)'
        end

        def rename_column(table_name, column_name, new_column_name)
          column = columns(table_name).find { |c| c.name.to_s == column_name.to_s }
          execute "ALTER TABLE #{quote_table_name(table_name)} CHANGE #{quote_column_name(column_name)} #{quote_column_name(new_column_name)} #{column.sql_type}"
        end

        def add_index(table_name, column_name, options = {})
          raise 'TODO: Implement me (add index)'
        end

        def remove_index(table_name, options = {})
          raise 'TODO: Implement me (remove index)'
        end

        def rename_index(table_name, old_name, new_name)
          raise 'TODO: Implement me (rename index)'
        end

        def index_name(table_name, options)
          raise 'TODO: Implement me (index name)'
        end

        def index_name_exists?(table_name, index_name, default = nil)
          raise 'TODO: Implement me (index name exists)'
        end

        def add_reference(table_name, ref_name, **options)
          raise 'TODO: Implement me (add reference)'
        end
        alias add_belongs_to add_reference

        def remove_reference(table_name, ref_name, foreign_key: false, polymorphic: false, **options)
          raise 'TODO: Implement me (remove reference)'
        end

        def foreign_keys(table_name)
          raise 'TODO: Implement me (foreign keys)'
        end

        def add_foreign_key(from_table, to_table, options = {})
          raise 'TODO: Implement me (add foreign key)'
        end

        def remove_foreign_key(from_table, options_or_to_table = {})
          raise 'TODO: Implement me (remove foreign key)'
        end

        def foreign_key_exists?(from_table, options_or_to_table = {})
          raise 'TODO: Implement me (foreign key exists)'
        end

        def foreign_key_for(from_table, options_or_to_table = {})
          raise 'TODO: Implement me foreign_ke_for'
        end

        def foreign_key_for!(from_table, options_or_to_table = {})
          raise 'TODO: Implement me foreign_key_for!'
        end

        def foreign_key_for_column_for(table_name)
          raise 'TODO: Implement me foreign_key_for_column_for'
        end

        def foreign_key_options(from_table, to_table, options)
          raise 'TODO: Implement me foreign_key_options'
        end

        def assume_migrated_upto_version(version, migration_paths)
          raise 'TODO: Implement me assume_migrated_upto_version'
        end

        def type_to_sql(type, limit: nil, precision: nil, scale: nil, **)
          case type
          when 'integer'
            case limit
            when 1 then 'TINYINT'
            when 2 then 'SMALLINT'
            when 3..4, nil then 'INT'
            when 5..8 then 'BIGINT'
            else
              raise(ActiveRecordError, 'Invalid integer precision')
            end
          else
            super
          end
        end

        def columns_for_distinct(columns, orders)
          columns
        end

        def add_timestamps(table_name, options = {})
          options[:null] = false if options[:null].nil?
          add_column table_name, :created_at, :datetime, options
          add_column table_name, :updated_at, :datetime, options
        end

        def remove_timestamps(table_name, options = {})
          remove_column table_name, :updated_at
          remove_column table_name, :created_at
        end

        def update_table_definition(table_name, base)
          raise 'TODO: Implement me'
        end

        def add_index_options(table_name, column_name, comment: nil, **options)
          raise 'TODO: Implement me'
        end

        def options_iclude_default?(options)
          raise 'TODO: Implement me'
        end

        def change_table_comment(table_name, comment)
          raise 'TODO: Implement me'
        end

        def change_column_comment(table_name, column_name, comment)
          raise 'TODO: Implement me'
        end

        private

        def schema_creation
          ::ActiveRecord::ConnectionAdapters::Kudu::SchemaCreation.new(self)
        end

        def create_table_definition(*args)
          ::ActiveRecord::ConnectionAdapters::Kudu::TableDefinition.new(*args)
        end

        def table_structure(table_name)
          quoted = quote_table_name table_name
          connection.query('DESCRIBE ' + quoted)
        end
      end
    end
  end
end
