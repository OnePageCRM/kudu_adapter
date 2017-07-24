# frozen_string_literal: true

require 'active_model/type/boolean'

module ActiveRecord
  module ConnectionAdapters
    module Kudu
      module Type
        class Boolean < ::ActiveModel::Type::Boolean
          def type
            :boolean
          end
        end
      end
    end
  end
end
