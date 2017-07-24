# frozen_string_literal: true

require 'active_model/type/integer'

module ActiveRecord
  module ConnectionAdapters
    module Kudu
      module Type
        # :nodoc:
        class SmallInt < ::ActiveModel::Type::Integer
          def type
            :smallint
          end

          def limit
            2
          end
        end
      end
    end
  end
end
