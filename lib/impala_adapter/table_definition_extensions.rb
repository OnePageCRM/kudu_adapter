# frozen_string_literal: true

module ImpalaAdapter
  # Definitions of additional table capabilities in Impala
  module TableDefinitionExtensions
    # @!attribute [r] partitions
    #  @return [Array] List of table partition definitions
    attr_reader :partitions

    # Define single partition
    # @param name [String] Parition name
    # @param type [String] Partition type
    # @param options [Hash] Parition options
    def partition(name, type, options = {})
      column(name, type, options)
      @partitions ||= []
      @partitions << @columns.pop
    end

    def row_format
      'ROW FORMAT DELIMITED FIELDS TERMINATED BY "\t"'
    end

    def external
      true
    end
  end
end
