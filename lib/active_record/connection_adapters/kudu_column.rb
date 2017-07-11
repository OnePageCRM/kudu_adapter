# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    # Basic class describing single column definition
    class KuduColumn < ActiveRecord::ConnectionAdapters::Column
      def initialize(name, default, sql_type, partition)
        super(name, default, sql_type)
        @partition = partition
      end

      def partition?
        @partition
      end
    end
  end
end
