# frozen_string_literal: true

require 'active_model/type/big_integer'

module ActiveRecord
  module ConnectionAdapters
    module Kudu
      module Type
        # :nodoc:
        class DateTime < ::ActiveModel::Type::BigInteger
          def type
            :datetime
          end

          def serialize(value)
            value.to_i
          end

          def deserialize(value)
            Time.at value.to_i
          end
        end
      end
    end
  end
end
