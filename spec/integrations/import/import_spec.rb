# frozen_string_literal: true

require "tempfile"
require "active_record"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :first_name
    t.string :last_name
    t.string :full_name
  end
end

class User < ActiveRecord::Base
  self.table_name = :users

  validates :full_name, presence: true

  has_and_belongs_to_many :skills, join_table: :skills_users
end

RSpec.describe "Import" do
  let(:row_model) do
    Class.new do
      include Csvbuilder::Model

      column :first_name, header: "First Name"
      column :last_name, header: "Last Name"

      class << self
        def name
          "BasicRowModel"
        end
      end
    end
  end

  let(:import_model) do
    Class.new(row_model) do
      include Csvbuilder::Import

      validates :first_name, presence: true, length: { minimum: 2 }
      validate :custom_last_name

      def full_name
        "#{first_name} #{last_name}"
      end

      def user
        User.new(first_name: first_name, last_name: last_name, full_name: full_name)
      end

      def custom_last_name
        errors.add(:last_name, "must be Doe") unless last_name == "Doe"
      end

      class << self
        def name
          "BasicImportModel"
        end
      end
    end
  end

  let(:csv_string) do
    CSV.generate do |csv|
      csv_source.each { |row| csv << row }
    end
  end

  let(:file) do
    file = Tempfile.new(["input_file", ".csv"])
    file.write(csv_string)
    file.rewind
    file
  end

  let(:options) { {} }

  let(:importer) { Csvbuilder::Import::File.new(file.path, import_model, options) }

  let(:row_enumerator) { importer.each }

  context "without user" do
    context "with valid CSV headers" do
      let(:csv_source) do
        [
          ["First Name", "Last Name"],
          %w[John Doe]
        ]
      end

      describe "#each" do
        context "when everything goes well" do
          it "imports users" do
            row_enumerator.each do |row_model|
              expect(row_model.headers).to eq(["First Name", "Last Name"])
              expect(row_model.source_headers).to eq(["First Name", "Last Name"])
              expect(row_model.source_row).to eq(%w[John Doe])

              expect(row_model.source_attributes.values).to eq(row_model.source_row)
              expect(row_model.formatted_attributes.values).to eq(row_model.original_attributes.values)

              user = row_model.user
              expect(user).to be_valid
              expect do
                user.save
              end.to change(User, :count).by(+1)

              expect(user.full_name).to eq("John Doe")
            end

            expect(User.count).to eq(1)
          end
        end
      end
    end

    context "with unvalid CSV headers" do
      let(:csv_source) do
        [
          ["First Name", "LastName"],
          %w[John Doe]
        ]
      end

      describe "#each" do
        context "when headers mismatch" do
          it "does not imports users" do
            expect { row_enumerator.next }.to raise_error(StopIteration)

            # TODO: Make the importer invalid
            # expect(importer).not_to be_valid

            expect(importer.headers).to eq(["First Name", "LastName"])

            expect(importer.current_row_model.headers).to eq(["First Name", "Last Name"])

            expect(importer.errors.full_messages).to eq(
              [
                "Headers mismatch. Given headers (First Name, LastName). Expected headers (First Name, Last Name). Unrecognized headers (LastName)."
              ]
            )

            expect(User.count).to eq(1)
          end
        end
      end
    end
  end
end
