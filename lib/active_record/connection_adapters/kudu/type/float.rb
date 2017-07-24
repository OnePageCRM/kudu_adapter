# frozen_string_literal: true

require 'active_model/type/float'

module ActiveRecord
  module ConnectionAdapters
    module Kudu
      module Type
        # :nodoc:
        class Float < ::ActiveModel::Type::Float
          def type
            :float
          end
        end
      end
    end
  end
end
