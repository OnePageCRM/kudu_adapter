# frozen_string_literal: true

require 'active_model/type/integer'

module ActiveRecord
  module ConnectionAdapters
    module Kudu
      module Type
        # :nodoc:
        class TinyInt < ::ActiveModel::Type::Integer
          def type
            :tinyint
          end

          def limit
            1
          end
        end
      end
    end
  end
end
