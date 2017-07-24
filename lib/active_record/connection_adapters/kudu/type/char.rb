# frozen_string_literal: true

require 'active_model/type/string'

module ActiveRecord
  module ConnectionAdapters
    module Kudu
      module Type
        class Char < ::ActiveModel::Type::String
          def type
            :char
          end
        end
      end
    end
  end
end
