# frozen_string_literal: true

require 'active_record/connection_adapters/column'

# :nodoc:
module ActiveRecord
  module ConnectionAdapters
    module Kudu
      # :nodoc:
      class Column < ::ActiveRecord::ConnectionAdapters::Column
        def initialize(name, default, sql_type_metadata = nil, null = true, table_name = nil, comment = nil)
          super(name, default, sql_type_metadata, null, table_name, nil, nil, comment: comment)
        end
      end
    end
  end
end
