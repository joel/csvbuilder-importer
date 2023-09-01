# frozen_string_literal: true

require "csvbuilder/core/concerns/attributes_base"

require "csvbuilder/importer/internal/import/attribute"

module Csvbuilder
  module Import
    module Attributes
      extend ActiveSupport::Concern
      include AttributesBase

      included do
        ensure_attribute_method
      end

      def valid?(*args)
        is_valid = super

        # The method attribute_objects was called by the valid? method through
        # the attribute getters. The memoization must be cleared now to propagate
        # the errors into the Attribute(s).
        instance_variable_set(:@attribute_objects, nil) unless is_valid

        is_valid
      end

      def attribute_objects
        @attribute_objects ||= _attribute_objects
      end

      def read_attribute_for_validation(attr)
        attr_index = source_headers.index(column_header(attr))
        return source_row[attr_index] unless attr_index.nil?

        nil
      end

      protected

      def _attribute_objects
        self.class.column_names.to_h do |column_name|
          [column_name, Attribute.new(column_name, read_attribute_for_validation(column_name), errors.to_hash[column_name], self)]
        end
      end

      class_methods do
        def define_attribute_method(column_name)
          return if super { original_attribute(column_name) }.nil?
        end
      end
    end
  end
end
