# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Csvbuilder::Import::ParsedModel" do
  describe "instance" do
    let(:source_row) { %w[alpha beta] }
    let(:options)    { { foo: :bar } }
    let(:klass)      { BasicImportModel }
    let(:instance)   { klass.new(source_row, options) }

    describe "#parsed_model" do
      subject(:parsed_model) { instance.parsed_model }

      it "returns parsed_model with methods working" do
        expect(parsed_model.alpha).to eql "alpha"
        expect(parsed_model.beta).to eql "beta"
      end

      # context "with format_cell" do
      #   it "format_cells first" do
      #     expect(klass).to receive(:format_cell).with("alpha", :alpha, kind_of(OpenStruct)).and_return(nil)
      #     expect(klass).to receive(:format_cell).with("beta", :beta, kind_of(OpenStruct)).and_return(nil)

      #     expect(subject.alpha).to be_nil
      #     expect(subject.beta).to be_nil
      #   end
      # end
    end

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
          klass.class_eval { validates :id, presence: true }
        end

        it do
          expect(import_model_valid).to be true
        end

        context "with empty row" do
          let(:source_row) { %w[] }

          it do
            expect(import_model_valid).to be false
          end
        end
      end

      context "when overriding validations" do
        before do
          klass.class_eval do
            validates :id, length: { minimum: 9 }
            parsed_model { validates :id, presence: true }
          end
        end

        it "takes the parsed_model_class validation into account" do
          expect(import_model_valid).to be false
          expect(instance.errors.full_messages).to eql ["Id is too short (minimum is 9 characters)"]
        end

        context "with empty row" do
          let(:source_row) { [""] }

          it "just shows the parsed_model_class validation too" do
            expect(import_model_valid).to be false
            expect(instance.errors.full_messages).to eql(
              [
                "Id is too short (minimum is 9 characters)",
                "Id can't be blank"
              ]
            )
          end
        end
      end
    end
  end
end
