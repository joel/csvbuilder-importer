# frozen_string_literal: true

require "csvbuilder/core/internal/attribute_base"

module Csvbuilder
  module Import
    class Attribute < Csvbuilder::AttributeBase
      attr_reader :source_value, :attribute_errors

      def initialize(column_name, source_value, attribute_errors, row_model)
        @source_value     = source_value
        @attribute_errors = attribute_errors

        super(column_name, row_model)
      end

      def value
        @value ||= if attribute_errors.present?
                     nil
                   else
                     formatted_value
                   end
      end

      def parsed_value
        @parsed_value ||= formatted_value
      end
    end
  end
end
