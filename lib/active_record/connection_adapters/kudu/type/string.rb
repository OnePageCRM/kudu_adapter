# frozen_string_literal: true

require 'active_model/type/string'

module ActiveRecord
  module ConnectionAdapters
    module Kudu
      module Type
        class String < ::ActiveModel::Type::String
          def type
            :string
          end
        end
      end
    end
  end
end
