# frozen_string_literal: true

require 'active_model/type/integer'

module ActiveRecord
  module ConnectionAdapters
    module Kudu
      module Type
        # :nodoc:
        class Integer < ::ActiveModel::Type::Integer
          def type
            :integer
          end

          def limit
            4
          end
        end
      end
    end
  end
end
