# frozen_string_literal: true

require 'active_record/connection_adapters/kudu_adapter'
module ActiveRecord
  # Create new connection with Impala database
  # @param config [::Hash] Connection configuration options
  class Base
    def self.impala_connection(config)
      ::ActiveRecord::ConnectionAdapters::KuduAdapter.new(config)
    end
  end
end
