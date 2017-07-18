# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    # Basic class describing single column definition
    class KuduColumn < ActiveRecord::ConnectionAdapters::Column
      # :nodoc:
      def initialize(name, default, sql_type, null = true, table_name = nil,
                     partition = false, default_function = nil,
                     comment = nil)
        super(name, default, sql_type, null, table_name, default_function,
              nil, comment)
        @partition = partition
      end

      def partition?
        @partition
      end
    end
  end
end
