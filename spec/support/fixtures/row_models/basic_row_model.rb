# frozen_string_literal: true

class BasicRowModel
  include Csvbuilder::Model

  column :alpha
  column :beta, header: "Beta Two"
end

#
# Import
#
class BasicImportModel < BasicRowModel
  include Csvbuilder::Import
end
