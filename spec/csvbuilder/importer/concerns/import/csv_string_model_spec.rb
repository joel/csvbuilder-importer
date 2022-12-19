# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Csvbuilder::Import::ParsedModel" do
  describe "instance" do
    let(:source_row) { %w[alpha beta] }
    let(:options)    { { foo: :bar } }
    let(:klass)      { BasicImportModel }
    let(:instance)   { klass.new(source_row, options) }

    describe "#valid?" do
      subject(:import_model_valid) { instance.valid? }

      let(:klass) do
        Class.new do
          include Csvbuilder::Model
          include Csvbuilder::Import

          column :id

          def self.name
            "TwoLayerValid"
          end
        end
      end

      context "with 1 validation" do
        before do
          klass.class_eval { validates :id, presence: true, length: { minimum: 9 } }
        end

        it do
          expect(import_model_valid).to be false
          expect(instance.errors.full_messages).to eql ["Id is too short (minimum is 9 characters)"]
        end

        context "with empty row" do
          let(:source_row) { [] }

          it do
            expect(instance.valid?).to be false
            expect(instance.errors.full_messages).to eql ["Id can't be blank",
                                                          "Id is too short (minimum is 9 characters)"]
          end
        end
      end
    end
  end
end
