# frozen_string_literal: true

require 'active_model/type/big_integer'

module ActiveRecord
  module ConnectionAdapters
    module Kudu
      module Type
        # :nodoc:
        class Time < ::ActiveModel::Type::BigInteger
          def type
            :time
          end

          def serialize(value)
            value.to_i
          end

          def deserialize(value)
            ::Time.at value.to_i
          end

          def user_input_in_time_zone(value)
            value.in_time_zone
          end
        end
      end
    end
  end
end
