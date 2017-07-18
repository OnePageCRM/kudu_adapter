# frozen_string_literal: true

require 'active_record/migration/join_table'

module ActiveRecord
  module ConnectionAdapters
    module Kudu
      include ::ActiveRecord::Migration::JoinTable

      # :nodoc:
      module SchemaStatements
        def native_database_types
          raise 'TODO: Implement me'
        end

        def table_options(table_name)
          raise 'TODO: Implement me'
        end

        def table_comment(table_name)
          raise 'TODO: Implement me'
        end

        def table_alias_for(table_name)
          table_name.tr('.', '_')
        end

        def data_sources
          tables | views
        end

        def data_source_exists?(name)
          raise 'TODO: Implement me'
        end

        def tables
          raise 'TODO: Implement me'
        end

        def table_exists?(table_name)
          raise 'TODO: Implement me'
        end

        def views
          raise 'TODO: Implement me'
        end

        def view_exists?(view_name)
          raise 'TODO: Implement me'
        end

        def indexes(table_name, name = nil)
          raise 'TODO: Implement me'
        end

        def index_exists?(table_name, column_name, options = {})
        raise 'TODO: Implement me'
        end

        def columns(table_name)
          raise 'TODO: Implement me'
        end

        def column_exists?(table_name, column_name, type = nil, options = {})
          raise 'TODO: Implement me'
        end

        def primary_key(table_name)
          raise 'TODO: Implement me'
        end

        def create_table(table_name, comment: nil, **options)
          raise 'TODO: Implement me'
        end

        def create_join_table(table_1, table_2, colum_options: {}, **options)
          raise 'TODO: Implement me'
        end

        def drop_join_table(table_1, table_2, options = {})
          raise 'TODO: Implement me'
        end

        def change_table(table_name, options = {})
          raise 'TODO: Implement me'
        end

        def rename_table(table_name, new_name)
          raise 'TODO: Implement me'
        end

        def drop_table(table_name, options = {})
          def add_column(table_name, column_name, type, options = {})
            raise 'TODO: Implement me'
          end
        end

        def remove_columns(table_name, column_names)
          raise 'TODO: Implement me'
        end

        def remove_column(table_name, column_name, type = nil, options = {})
          raise 'TODO: Implement me'
        end

        def change_column(table_name, type, options)
          raise 'TODO: Implement me'
        end

        def change_column_default(table_name, column_name, default_or_changes)
          raise 'TODO: Implement me'
        end

        def change_column_null(table_name, column_name, null, default = nil)
          raise 'TODO: Implement me'
        end

        def rename_column(table_name, column_name, new_column_name)
          raise 'TODO: Implement me'
        end

        def add_index(table_name, column_name, options = {})
          raise 'TODO: Implement me'
        end

        def remove_index(table_name, options = {})
          raise 'TODO: Implement me'
        end

        def rename_index(table_name, old_name, new_name)
          raise 'TODO: Implement me'
        end

        def index_name(table_name, options)
          raise 'TODO: Implement me'
        end

        def index_name_exists?(table_name, index_name, default = nil)
          raise 'TODO: Implement me'
        end

        def add_reference(table_name, ref_name, **options)
          raise 'TODO: Implement me'
        end
        alias add_belongs_to add_reference

        def remove_reference(table_name, ref_name, foreign_key: false, polymorphic: false, **options)
          raise 'TODO: Implement me'
        end

        def foreign_keys(table_name)
          raise 'TODO: Implement me'
        end

        def add_foreign_key(from_table, to_table, options = {})
          raise 'TODO: Implement me'
        end

        def remoe_foreign_key(from_table, options_or_to_table = {})
          raise 'TODO: Implement me'
        end

        def foreign_key_exists?(from_table, options_or_to_table = {})
          raise 'TODO: Implement me'
        end

        def foreign_key_for(from_table, options_or_to_table = {})
          raise 'TODO: Implement me'
        end

        def foreign_key_for!(from_table, options_or_to_table = {})
          raise 'TODO: Implement me'
        end

        def foreign_key_for_column_for(table_name)
          raise 'TODO: Implement me'
        end

        def foreign_key_options(from_table, to_table, options)
          raise 'TODO: Implement me'
        end

        def dump_schema_information
          raise 'TODO: Implement me'
        end

        def insert_versions_sql(versions)
          raise 'TODO: Implement me'
        end

        def assume_migrated_upto_version(version, migration_paths)
          raise 'TODO: Implement me'
        end

        def type_to_sql(type, limit: nil, precision: nil, scale: nil, **)
          raise 'TODO: Implement me'
        end

        def columns_for_distinct(columns, orders)
          raise 'TODO: Implement me'
        end

        def add_timestamps(table_name, options = {})
          raise 'TODO: Implement me'
        end

        def remove_timestamps(table_name, options = {})
          raise 'TODO: Implement me'
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
      end
    end
  end
end
