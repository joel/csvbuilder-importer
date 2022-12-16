# frozen_string_literal: true

require "csvbuilder/core/internal/attribute_base"

class BasicAttribute < Csvbuilder::AttributeBase
  def value
    source_value.gsub("_source", "")
  end

  def source_value
    "#{row_model.public_send(column_name)}_source"
  end
end

module BasicAttributes
  extend ActiveSupport::Concern

  include Csvbuilder::AttributesBase

  attr_reader :source_row

  included do
    ensure_attribute_method
  end

  def initialize(*source_row)
    @source_row = source_row
  end

  def attribute_objects
    @attribute_objects ||= array_to_block_hash(self.class.column_names) do |column_name|
      BasicAttribute.new(column_name, self)
    end
  end

  def context
    OpenStruct.new
  end

  class_methods do
    def define_attribute_method(column_name)
      super { source_row[self.class.columns.keys.index(column_name)] }
    end
  end
end
