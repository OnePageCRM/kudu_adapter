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
              bind = "'#{bind}'" if bind.is_a? ::String # TODO: proper escape
              sql = sql.sub('?', bind.to_s)
            end
          end

          result = connection.query sql
          columns = result.first&.keys.to_a
          rows = result.map { |row| row.fetch_values(*columns) }
          ::ActiveRecord::Result.new(columns.map(&:to_s), rows)
        end
      end
    end
  end
end
