# frozen_string_literal: true

require 'active_record/result'

module ActiveRecord
  module ConnectionAdapters
    module Kudu
      # :nodoc:
      module DatabaseStatements
        # :nodoc:
        def exec_query(sql, _ = 'SQL', binds = [], prepare: false)
          ::Rails.logger.warn 'Prepared statements are not supported' if prepare

          unless without_prepared_statement? binds
            type_casted_binds(binds).each do |bind|
              bind = quote(bind)
              sql = sql.sub('?', bind.to_s)
            end
          end
          ::Rails.logger.info 'QUERY : ' + sql.to_s
          result = connection.query sql
          columns = result.first&.keys.to_a
          rows = result.map { |row| row.fetch_values(*columns) }
          ::ActiveRecord::Result.new(columns.map(&:to_s), rows)
        end

        def exec_delete(sql, name, binds)
          # We are not able to return number of affected rows so we will just say that there was some update
          super
          1
        end

        def exec_update(sql, name, binds)
          # We are not able to return number of affected rows so we will just say that there was some update
          super
          1
        end
      end
    end
  end
end
