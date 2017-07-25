# frozen_string_literal: true

require 'active_record/result'

module ActiveRecord
  module ConnectionAdapters
    module Kudu
      # :nodoc:
      module DatabaseStatements
        # :nodoc:
        def exec_query(sql, name = 'SQL', binds = [], prepare: false)
          result = connection.query sql
          columns = result.first&.keys.to_a
          rows = result.map { |row| row.fetch_values(*columns) }
          ::ActiveRecord::Result.new(columns.map(&:to_s), rows)
        end
      end
    end
  end
end
