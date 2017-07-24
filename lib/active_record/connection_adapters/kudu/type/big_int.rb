# frozen_string_literal: true

require 'active_model/type/integer'

module ActiveRecord
  module ConnectionAdapters
    module Kudu
      module Type
        # :nodoc:
        class BigInt < ::ActiveModel::Type::Integer
          def type
            :bigint
          end

          def limit
            8
          end
        end
      end
    end
  end
end
