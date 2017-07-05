# frozen_string_literal: true

require 'arel/visitors/impala'
module ImpalaAdapter
  # Bind substition class definition
  class BindSubstition < ::Arel::Visitors::Impala
    include ::Arel::Visitors::BindVisitor
  end
end
