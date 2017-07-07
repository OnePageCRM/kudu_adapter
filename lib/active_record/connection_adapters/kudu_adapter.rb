# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    # Main Impala connection adapter class
    class KuduAdapter < ::ActiveRecord::ConnectionAdapters::AbstractAdapter
      ADAPTER_NAME = 'Kudu'

      def initialize(configuration)
        # TODO: allow extra connnection options
        self.impala_connection = ::Kudu.connect(
          configuration[:host] || '127.0.0.1',
          configuration[:port] || 28_050
        )
      end

      protected

      # @!attribute [r] impala_connection
      #  @return [::Impala::Connection] Connection which we are working on
      attr_accessor :impala_connection
    end
  end
end
