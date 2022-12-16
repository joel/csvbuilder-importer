# frozen_string_literal: true

require "csvbuilder/core/concerns/attributes_base"

require "csvbuilder/importer/internal/import/attribute"
require "csvbuilder/importer/concerns/import/parsed_model"

module Csvbuilder
  module Import
    module Attributes
      extend ActiveSupport::Concern
      include AttributesBase
      include ParsedModel

      included do
        ensure_attribute_method
      end

      def attribute_objects
        @attribute_objects ||= _attribute_objects
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
          super { original_attribute(column_name) }
        end
      end
    end
  end
end
