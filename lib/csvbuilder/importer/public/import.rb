# frozen_string_literal: true

require "csvbuilder/core/public/model"
require "csvbuilder/importer/concerns/import/base"
require "csvbuilder/importer/concerns/import/attributes"

module Csvbuilder
  # Include this to with {Model} to have a RowModel for importing csvs.
  module Import
    extend ActiveSupport::Concern

    include Csvbuilder::Model

    include ActiveModel::Validations

    include Base
    include Attributes
  end
end
