# frozen_string_literal: true

require "csvbuilder/importer/internal/import/csv"

module Csvbuilder
  module Import
    # Represents a csv file and handles parsing to return `Import`
    class File
      extend ActiveModel::Callbacks
      include ActiveModel::Validations

      attr_reader :interrupt, :csv, :row_model_class, :index, :current_row_model, :previous_row_model, :context # -1 = start of file, 0 to infinity = index of row_model, nil = end of file, no row_model

      delegate :size, :end_of_file?, :line_number, to: :csv

      define_model_callbacks :each_iteration
      define_model_callbacks :next
      define_model_callbacks :abort, :skip, only: :before

      validate { errors.merge!(csv.errors) unless csv.valid? }

      # @param [String] file_path path of csv file
      # @param [Import] row_model_class model class returned for importing
      # @param context [Hash] context passed to the {Import}
      def initialize(file_path, row_model_class, context = {})
        @csv             = ::Csvbuilder::Import::Csv.new(file_path) # Full namespace provided to avoid confusion with Ruby CSV class.
        @row_model_class = row_model_class
        @context         = context.to_h.symbolize_keys
        @interrupt = false
        reset
      end

      def headers
        h = csv.headers
        h.instance_of?(Array) ? h : []
      end

      # Resets the file back to the top
      def reset
        csv.reset
        @index = -1
        @current_row_model = nil
        @interrupt = false
      end

      # Gets the next row model based on the context
      def next(context = {})
        return if end_of_file?

        run_callbacks :next do
          context = context.to_h.reverse_merge(self.context)
          @previous_row_model = current_row_model

          @index += 1
          @current_row_model = row_model_class.next(self, context)

          # Check if the headers are valid
          if previous_row_model.nil? # First row
            headers_count
            headers_mismatch
            abort! if errors.where(:headers).any?
          end

          @current_row_model = @index = nil if end_of_file?
        end

        current_row_model
      end

      # Iterates through the entire csv file and provides the `current_row_model` in a block, while handing aborts and skips
      # via. calling {Model#abort?} and {Model#skip?}
      def each(context = {})
        return to_enum(__callee__, context) unless block_given?
        return false if _abort?

        while self.next(context)
          run_callbacks :each_iteration do
            return false if _abort?
            next if _skip?

            yield current_row_model
          end
        end
      end

      # @return [Boolean] returns true, if the file should abort reading
      def abort?
        interrupt || !valid? || !!current_row_model.try(:abort?)
      end

      def abort!
        @interrupt = true

        nil
      end

      # @return [Boolean] returns true, if the file should skip `current_row_model`
      def skip?
        !!current_row_model.try(:skip?)
      end

      protected

      def _abort?
        abort = abort?
        run_callbacks(:abort) if abort
        abort
      end

      def _skip?
        skip = skip?
        run_callbacks(:skip) if skip
        skip
      end

      #
      # Validations
      #
      def headers_invalid_row
        errors.add(:csv, "has header with #{csv.headers.message}") if csv.headers.class < Exception
      end

      def headers_count
        return if headers_invalid_row || !csv.valid?
        return if row_model_class.try(:row_names) # FileModel check

        size_until_blank = ((headers || []).map { |h| h.try(:strip) }.rindex(&:present?) || -1) + 1
        column_names = row_model_class.column_names

        return if size_until_blank == column_names.size

        expected_headers_size = column_names.size

        message = [
          "count does not match.",
          " Given headers (#{size_until_blank}).",
          " Expected headers (#{expected_headers_size}): #{column_names.join(", ")}."
        ]

        errors.add(:headers, message.join)
      end

      def headers_mismatch
        return if headers_invalid_row || !csv.valid?
        return if row_model_class.try(:row_names) # FileModel check

        return if headers == row_model_class.headers

        unrecognized_headers = headers - current_row_model.headers

        message = [
          "mismatch.",
          " Given headers (#{headers.join(", ")}).",
          " Expected headers (#{row_model_class.headers.join(", ")}).",
          " Unrecognized headers (#{unrecognized_headers.join(", ")})."
        ]

        errors.add(:headers, message.join)
      end
    end
  end
end
