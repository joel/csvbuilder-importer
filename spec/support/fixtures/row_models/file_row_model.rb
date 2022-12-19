# frozen_string_literal: true

class FileRowModel
  include Csvbuilder::Model
  include Csvbuilder::Model::FileModel

  row :alpha
  row :beta, header: "String 2"

  class << self
    def format_header(column_name, _context)
      "HEADER <- #{column_name} -> HEADER"
    end
  end
end

#
# Import
#
class FileImportModel < FileRowModel
  include Csvbuilder::Import
  include Csvbuilder::Import::FileModel
end
