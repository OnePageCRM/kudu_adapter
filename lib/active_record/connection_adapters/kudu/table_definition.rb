# frozen_string_literal: true

require 'active_record/connection_adapters/abstract/schema_definitions'

module ActiveRecord
  module ConnectionAdapters
    module Kudu
      # :nodoc:
      class TableDefinition < ::ActiveRecord::ConnectionAdapters::TableDefinition
        attr_reader :external
        attr_reader :partitions_count
        attr_reader :partition_columns

        def initialize(name, temporary = false, options = nil, as = nil, comment: nil)
          super
          @external = options&.[](:external)
          @partitions_count = options&.[](:partitions_count)
          @partition_columns = options&.[](:partition_columns)
        end

        def double(*args, **options)
          args.each { |name| column(name, :double, options) }
        end

        def float(*args, **options)
          args.each { |name| column(name, :float, options) }
        end

      end
    end
  end
end
