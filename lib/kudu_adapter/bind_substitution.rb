# frozen_string_literal: true

require 'arel/visitors/bind_visitor'
require 'arel/visitors/kudu'

module KuduAdapter
  # Bind substition class definition
  class BindSubstition < ::Arel::Visitors::Kudu
    include ::Arel::Visitors::BindVisitor

    def preparable
      false
    end
  end
end
