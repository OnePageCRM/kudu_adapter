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
          nil
        end

        def table_comment(table_name)
          raise NotImplementedError, '#table_comment Comments not implemented'
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
          []
        end

        def index_exists?(table_name, column_name, options = {})
          raise NotImplementedError, '#index_exists? Indexing not implemented'
        end

        def columns(table_name)
          table_structure(table_name).map do |col_def|
            type = if col_def[:type] == 'int'
                     :integer
                   elsif col_def[:type] == 'bigint' && /(_at|_date|_time)$/ =~ col_def[:name]
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

        def drop_temp_tables
          tbl = tables
          to_delete = tbl.select {|tbl| tbl.include? '_temp' }
          to_delete.each do |dt|
            drop_table(dt)
          end
        end

        def create_join_table(table_1, table_2, colum_options: {}, **options)
          join_table_name = find_join_table_name(table_1, table_2, options)

          column_options = options.delete(:column_options) || {}
          column_options.reverse_merge!(null: false)
          column_options.merge!(primary_key: true)

          t1_column, t2_column = [table_1, table_2].map{ |t| t.to_s.singularize.foreign_key }

          create_table(join_table_name, options.merge!(id: false)) do |td|
            td.string t1_column, column_options
            td.string t2_column, column_options
            yield td if block_given?
          end
        end

        def drop_join_table(table_1, table_2, options = {})
          join_table_name = find_join_table_name(table_1, table_2, options)
          drop_table join_table_name
        end

        def change_table(table_name, options = {})
          if supports_bulk_alter? && options[:bulk]
            recorder = ActiveRecord::Migration::CommandRecorder.new(self)
            yield update_table_definition(table_name, recorder)
            bulk_change_table(table_name, recorder.commands)
          else
            yield update_table_definition(table_name, self)
          end
        end

        def rename_table(table_name, new_name)
          db_name = Rails.configuration.database_configuration[Rails.env]['database']
          execute "ALTER TABLE #{quote_table_name(table_name)} RENAME TO #{quote_table_name(new_name)}"
          execute "ALTER TABLE #{quote_table_name(new_name)} SET TblProperties('kudu.table_name' = 'impala::#{db_name}.#{new_name}')"
        end

        def add_column(table_name, column_name, type, options = {})
          if options_has_primary_key(options)
            # be aware of primary key columns
            redefine_table_add_primary_key(table_name, column_name, type, options)
          else
            at = create_alter_table table_name
            at.add_column(column_name, type, options)
            execute schema_creation.accept at
          end
        end

        def remove_columns(table_name, column_names)
          raise ArgumentError.new("You must specify at least one column name. Example: remove_columns(:people, :first_name)") if column_names.empty?
          column_names.each do |column_name|
            remove_column(table_name, column_name)
          end
        end

        def remove_column(table_name, column_name, type = nil, options = {})
          if primary_keys_contain_column_name(table_name, column_name)
            # be aware of primary key columns
            #raise ArgumentError.new("You cannot drop primary key fields")
            redefine_table_drop_primary_key(table_name, column_name, type, options)
          else
            execute "ALTER TABLE #{quote_table_name(table_name)} DROP COLUMN #{quote_column_name(column_name)}"
          end
        end

        def change_column(table_name, column_name, type, options)
          raise NotImplementedError, '#change_column Altering columns not implemented'
        end

        def change_column_default(table_name, column_name, default_or_changes)
          raise NotImplementedError, '#change_column_default Altering column defaults not implemented'
        end

        def change_column_null(table_name, column_name, null, default = nil)
          raise NotImplementedError, '#change_column_null Altering column null not implemented'
        end

        def rename_column(table_name, column_name, new_column_name)
          raise ArgumentError.new('You cannot rename primary key fields') if primary_keys_contain_column_name(table_name, column_name)
          column = columns(table_name).find { |c| c.name.to_s == column_name.to_s }
          execute "ALTER TABLE #{quote_table_name(table_name)} CHANGE #{quote_column_name(column_name)} #{quote_column_name(new_column_name)} #{column.sql_type}"
        end

        # It will reload all data from temp table name into new one.
        # We're seeking for table_name_temp while we inserting data with additional new column and it's value.
        # At the end table_name_temp is dropped indeed.
        def reload_table_data(table_name, column_name, options = {})
          temp_table_name = table_name + '_temp'

          # get table structure and remove our column name
          columns = table_structure table_name
          columns.reject! { |c| c[:name] == column_name.to_s }

          select_qry = columns.map {|col| col[:name].to_s }.join(',')

          # values with additional column name
          values = select_qry + ',' + column_name.to_s
          # fetch values with our column name and value to insert
          fetch_values = select_qry + ',' + quote(options[:default]) + ' AS ' + column_name.to_s

          insert_qry = "INSERT INTO #{quote_table_name(table_name)} (#{values}) SELECT #{fetch_values} FROM #{quote_table_name(temp_table_name)}"
          execute insert_qry

          drop_table(temp_table_name)
        end

        def add_index(table_name, column_name, options = {})
          p '(add_index) Indexing not supported by Apache KUDU'
        end

        def remove_index(table_name, options = {})
          p '(remove_index) Indexing not supported by Apache KUDU'
        end

        def rename_index(table_name, old_name, new_name)
          p '(rename_index) Indexing not supported by Apache KUDU'
        end

        def index_name(table_name, options)
          p '(index_name) Indexing not supported by Apache KUDU'
        end

        def index_name_exists?(table_name, index_name, default = nil)
          p '(index_name_exists?) Indexing not supported by Apache KUDU'
        end

        def add_reference(table_name, ref_name, **options)
          p '(add_reference) Traditional referencing not supported by Apache KUDU'
        end
        alias add_belongs_to add_reference

        def remove_reference(table_name, ref_name, foreign_key: false, polymorphic: false, **options)
          p '(remove_reference) Traditional referencing not supported by Apache KUDU'
        end

        def foreign_keys(table_name)
          p '(foreign_keys) Foreign keys not supported by Apache KUDU'
        end

        def add_foreign_key(from_table, to_table, options = {})
          p '(add_foreign_key) Foreign keys not supported by Apache KUDU'
        end

        def remove_foreign_key(from_table, options_or_to_table = {})
          p '(remove_foreign_key) Foreign keys not supported by Apache KUDU'
        end

        def foreign_key_exists?(from_table, options_or_to_table = {})
          p '(foreign_key_exists?) Foreign keys not supported by Apache KUDU'
        end

        def foreign_key_for(from_table, options_or_to_table = {})
          p '(foreign_key_for?) Foreign keys not supported by Apache KUDU'
        end

        def foreign_key_for!(from_table, options_or_to_table = {})
          p '(foreign_key_for!) Foreign keys not supported by Apache KUDU'
        end

        def foreign_key_for_column_for(table_name)
          p '(foreign_key_for_column_for) Foreign keys not supported by Apache KUDU'
        end

        def foreign_key_options(from_table, to_table, options)
          p '(foreign_key_options) Foreign keys not supported by Apache KUDU'
        end

        def assume_migrated_upto_version(version, migrations_paths)
          migrations_paths = Array(migrations_paths)
          version = version.to_i
          sm_table = quote_table_name(ActiveRecord::SchemaMigration.table_name)

          migrated = ActiveRecord::SchemaMigration.all_versions.map(&:to_i)
          versions = ActiveRecord::Migrator.migration_files(migrations_paths).map do |file|
            ActiveRecord::Migrator.parse_migration_filename(file).first.to_i
          end

          unless migrated.include?(version)
            execute "INSERT INTO #{sm_table} (version) VALUES (#{quote(version.to_s)})"
          end

          inserting = (versions - migrated).select { |v| v < version }
          if inserting.any?
            if (duplicate = inserting.detect { |v| inserting.count(v) > 1 })
              raise "Duplicate migration #{duplicate}. Please renumber your migrations to resolve the conflict."
            end
            if supports_multi_insert?
              execute insert_versions_sql(inserting)
            else
              inserting.each do |v|
                execute insert_versions_sql(v.to_s)
              end
            end
          end
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
          Table.new(table_name, base)
        end

        def add_index_options(table_name, column_name, comment: nil, **options)
          p '(add_index_options) Indexing not supported by Apache KUDU'
        end

        def options_include_default?(options)
          options.include?(:default) && !(options[:null] == false && options[:default].nil?)
        end

        def change_table_comment(table_name, comment)
          p '(change_table_comment) Altering table comments not supported by Apache KUDU'
        end

        def change_column_comment(table_name, column_name, comment)
          p '(change_column_comment) Altering column comments not supported by Apache KUDU'
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

        # check if options contains primary_key
        def options_has_primary_key(options)
          options[:primary_key] = false if options[:primary_key].nil?
          options[:primary_key]
        end

        def primary_keys_contain_column_name(table_name, column_name)
          pks = primary_key(table_name)
          pks.include? column_name.to_s
        end

        def set_options_from_column_definition(column)
          opt = {}
          opt[:primary_key] = ActiveModel::Type::Boolean.new.cast(column[:primary_key]) if column[:primary_key].present?
          opt[:null] = ActiveModel::Type::Boolean.new.cast(column[:nullable]) if column[:nullable].present?
          opt[:default] = lookup_cast_type(column[:type]).serialize(column[:default_value]) if column[:default_value].present?
          # TODO: Do we have more options ?
          opt
        end

        # This method will copy existing structure of table with added new field.
        # It works only if we're adding new primary key on existing table.
        def redefine_table_add_primary_key(table_name, column_name, type, options = {})

          redefined_table_name = table_name + '_redefined'
          temp_table_name = table_name + '_temp'

          columns = table_structure table_name
          pk_columns = columns.select {|c| c[:primary_key] == 'true'}
          non_pk_columns = columns.select {|c| c[:primary_key] == 'false'}

          create_table(redefined_table_name, { id: false }) do |td|

            # existing pk columns
            pk_columns.each do |col|
              td.send col[:type].to_sym, col[:name], set_options_from_column_definition(col)
            end

            # add new column
            td.send type, column_name, options

            non_pk_columns.each do |col|
              td.send col[:type].to_sym, col[:name], set_options_from_column_definition(col)
            end

          end

          # rename existing table to temp
          rename_table(table_name, temp_table_name)
          # rename newly created to active one
          rename_table(redefined_table_name, table_name)

        end

        # This method will copy existing structure of table with primary key field removed.
        # It works only if we're removing primary key on existing table.
        def redefine_table_drop_primary_key(table_name, column_name, type, options = {})

          redefined_table_name = table_name + '_redefined'
          temp_table_name = table_name + '_temp'

          columns = table_structure table_name
          columns.reject! { |c| c[:name] == column_name.to_s }

          create_table(redefined_table_name, { id: false }) do |td|
            columns.each do |col|
              td.send col[:type].to_sym, col[:name], set_options_from_column_definition(col)
            end
          end

          # rename existing table to temp
          rename_table(table_name, temp_table_name)
          # rename newly created to active one
          rename_table(redefined_table_name, table_name)

          # copy reduced existing data into new table
          select_qry = columns.map {|col| col[:name].to_s }.join(',')
          copy_qry = "INSERT INTO #{quote_table_name(table_name)} (#{select_qry}) SELECT #{select_qry} FROM #{quote_table_name(temp_table_name)}"
          execute copy_qry

          # finally, drop temp table
          drop_table(temp_table_name)

        end

      end
    end
  end
end
