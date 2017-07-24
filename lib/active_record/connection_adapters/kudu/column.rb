# frozen_string_literal: true

require 'active_record/connection_adapters/column'

# :nodoc:
module ActiveRecord
  module ConnectionAdapters
    module Kudu
      # :nodoc:
      class Column < ::ActiveRecord::ConnectionAdapters::Column
      end
    end
  end
end
