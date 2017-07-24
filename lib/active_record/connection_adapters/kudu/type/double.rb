# frozen_string_literal: true

require 'active_model/type/float'

module ActiveRecord
  module ConnectionAdapters
    module Kudu
      module Type
        class Double < ::ActiveModel::Type::Float
          def type
            :double
          end
        end
      end
    end
  end
end
