# frozen_string_literal: true

module Csvbuilder
  # Include this to with {Model} to have a RowModel for importing CSVs that
  # represents just one model.
  # It needs Csvbuilder::Import
  module Import
    module FileModel
      extend ActiveSupport::Concern

      class_methods do
        # Safe to override
        #
        # @param cell [String] the cell's string
        # @return [Integer] returns index of the header_match that cell match
        def index_header_match(cell, context)
          match = header_matchers(context).each_with_index.find do |matcher, _index|
            cell.match(matcher)
          end

          match ? match[1] : nil
        end

        def header_matchers(context)
          @header_matchers ||= row_names.filter_map do |row_name|
            formatted_header = format_header(row_name, context)

            Regexp.new("^#{formatted_header}$", Regexp::IGNORECASE) if formatted_header
          end
        end

        def next(file, context = {})
          csv = file.csv

          return csv.read_row unless csv.next_row

          source_row = Array.new(header_matchers(context).size)

          while csv.next_row
            current_row = csv.read_row

            current_row.each.with_index do |cell, position|
              next if position.zero?
              next if cell.blank?

              index = index_header_match(cell, context)
              next unless index

              source_row[index] = current_row[position + 1]

              break
            end
          end

          new(source_row, source_headers: csv.headers, context: context, previous: file.previous_row_model)
        end
      end
    end
  end
end
