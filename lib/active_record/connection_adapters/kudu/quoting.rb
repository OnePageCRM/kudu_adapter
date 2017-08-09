# frozen_string_literal: true

require 'active_support/core_ext/big_decimal/conversions'
require 'active_support/multibyte/chars'

module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module Kudu
      module Quoting

        QUOTED_TRUE, QUOTED_FALSE = true.to_s, false.to_s

        def quote_column_name(column_name)
          column_name.to_s
        end

        def quote_table_name(table_name)
          quote_column_name table_name
        end

        def quote_default_expression(value, column) # :nodoc:
          if value.is_a?(Proc)
            value.call
          else
            value = lookup_cast_type(column.sql_type).serialize(value)
            # DOUBLE, FLOAT represented as 0.0 but KUDU supports only DEFAULT statement as 0
            value = 0 if value.to_i == 0 if %w(DOUBLE FLOAT).include? column.sql_type
            quote(value)
          end
        end

        def quoted_true
          QUOTED_TRUE
        end

        def unquoted_true
          true
        end

        def quoted_false
          QUOTED_FALSE
        end

        def unquoted_false
          false
        end

      end
    end
  end
end
