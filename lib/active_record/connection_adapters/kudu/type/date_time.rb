# frozen_string_literal: true

require 'active_model/type/helpers/time_value'
require 'active_record/connection_adapters/kudu/type/time'

module ActiveRecord
  module ConnectionAdapters
    module Kudu
      module Type
        include ::ActiveModel::Type::Helpers::TimeValue

        # :nodoc:
        class DateTime < ::ActiveRecord::ConnectionAdapters::Kudu::Type::Time
          def type
            :datetime
          end
        end
      end
    end
  end
end
