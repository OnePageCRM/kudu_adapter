# frozen_string_literal: true

require 'active_record/connection_adapters/sql_type_metadata'

module ActiveRecord
  module ConnectionAdapters
    module Kudu
      # :nodoc:
      class SqlTypeMetadata < ::ActiveRecord::ConnectionAdapters::SqlTypeMetadata
        def initialize(sql_type: nil, type: nil)
          super(sql_type: sql_type, type: type, limit: nil, precision: nil, scale: nil)
        end
      end
    end
  end
end
