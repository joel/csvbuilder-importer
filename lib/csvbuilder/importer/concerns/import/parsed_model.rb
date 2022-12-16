# frozen_string_literal: true

module Csvbuilder
  module Import
    module ParsedModel
      extend ActiveSupport::Concern

      def parsed_model
        @parsed_model ||= begin
          attribute_objects = _attribute_objects
          formatted_hash = array_to_block_hash(self.class.column_names) do |column_name|
            attribute_objects[column_name].formatted_value
          end
          self.class.parsed_model_class.new(formatted_hash.values)
        end
      end

      class_methods do
        def parsed_model_class
          @parsed_model_class ||= self
        end

        protected

        def parsed_model(&block)
          parsed_model_class.class_eval(&block)
        end
      end
    end
  end
end
