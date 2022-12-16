# frozen_string_literal: true

require "csvbuilder/importer/version"

require "csv"
require "ostruct"
require "active_model"

require "active_support"
require "active_support/dependencies/autoload"
require "active_support/core_ext/object"
require "active_support/core_ext/string"

require "csvbuilder/core"

# require "csvbuilder/core/version"
# puts("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! => #{::Csvbuilder::Core::VERSION}")

# require "csvbuilder/core/public/model"
# ::Csvbuilder::Model

# require "csvbuilder/core/concerns/attributes_base"
# ::Csvbuilder::AttributesBase

# require "csvbuilder/core/internal/attribute_base"
# ::Csvbuilder::AttributeBase

# require "csvbuilder/importer/model"
# require "model"
# require "file_model"

require "csvbuilder/importer/public/import"
require "csvbuilder/importer/public/import/file_model"
require "csvbuilder/importer/public/import/file"
