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
        @attribute_objects ||= _attribute_objects(errors)
      end

      protected

      def _attribute_objects(attributes_errors = {})
        index = -1

        array_to_block_hash(self.class.column_names) do |column_name|
          Attribute.new(column_name, source_row[index += 1], attributes_errors[column_name], self)
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
