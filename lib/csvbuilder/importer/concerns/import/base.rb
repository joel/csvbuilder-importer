# frozen_string_literal: true

module Csvbuilder
  module Import
    module Base
      extend ActiveSupport::Concern

      included do
        attr_reader :source_headers, :source_row, :line_number, :index, :previous

        validate { errors.add(:csv, "has #{@csv_exception.message}") if @csv_exception }
      end

      # @param [Array] source_row_or_exception the csv row
      # @param options [Hash]
      # @option options [Integer] :index 1st row_model is 0, 2nd is 1, 3rd is 2, etc.
      # @option options [Integer] :line_number line_number in the CSV file
      # @option options [Array] :source_headers the csv header row
      # @option options [Csvbuilder::Import] :previous the previous row model
      # @option options [Csvbuilder::Import] :parent if the instance is a child, pass the parent
      def initialize(source_row_or_exception = [], options = {})
        @source_row     = source_row_or_exception
        @csv_exception  = source_row if source_row.is_a? Exception
        @source_row     = [] if source_row_or_exception.class != Array

        @line_number    = options[:line_number]
        @index          = options[:index]
        @source_headers = options[:source_headers]

        @previous       = options[:previous].try(:dup)

        previous.try(:free_previous)

        super(options)
      end

      # Free `previous` from memory to avoid making a linked list
      def free_previous
        attributes
        @previous = nil
      end

      # Safe to override.
      #
      # @return [Boolean] returns true, if this instance should be skipped
      def skip?
        !valid?
      end

      # Safe to override.
      #
      # @return [Boolean] returns true, if the entire csv file should stop reading
      def abort?
        false
      end

      class_methods do
        #
        # Move to Import::File once FileModel is removed.
        #
        # @param [Import::File] file to read from
        # @param [Hash] context extra data you want to work with the model
        # @param [Import] prevuous the previous row model
        # @return [Import] the next model instance from the csv
        def next(file, context = {})
          csv = file.csv

          csv.skip_headers
          csv.read_row

          new(csv.current_row,
              line_number: csv.line_number,
              index: file.index,
              source_headers: csv.headers,
              context: context,
              previous: file.previous_row_model)
        end
      end
    end
  end
end
