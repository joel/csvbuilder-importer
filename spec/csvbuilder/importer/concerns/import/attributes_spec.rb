# frozen_string_literal: true

require "spec_helper"

module Csvbuilder
  module Import
    RSpec.describe Attributes do
      let(:row_model_class) { Class.new BasicImportModel }
      let(:source_row)      { %w[alpha beta] }
      let(:options)         { { foo: :bar, source_headers: ["Alpha", "Beta Two"] } }
      let(:instance)        { row_model_class.new(source_row, options) }

      describe "instance" do
        describe "define methods" do
          it { expect(instance).to respond_to(:alpha) }
        end

        describe "#attribute_objects" do
          subject(:attribute_objects) { instance.attribute_objects }

          it "returns a hash of cells mapped to their column_name" do
            expect(attribute_objects.keys).to eql row_model_class.column_names
            expect(attribute_objects.values.map(&:class)).to eql [Csvbuilder::Import::Attribute] * 2

            # ensure that attributes are correctly set
            {alpha: "alpha", beta: "beta"}.each do |attr, value|
              expect(attribute_objects[attr].value).to eql value
            end
          end

          context "when invalid" do
            let(:row_model_class) do
              Class.new(BasicImportModel) do
                validates :alpha, format: { with: /\A\d+\z/ }

                def self.name
                  "BasicImportModelWithValidation"
                end

                def self.format_cell(*args)
                  args[0..1].join(" :: - :: ")
                end
              end
            end

            it "returns the cells with the right attributes" do
              allow(instance).to receive(:valid?).and_call_original

              expect(instance.valid?).to be false
              expect(instance.errors.full_messages).to eql ["Alpha is invalid"]
              expect(instance.errors.full_messages).to eql(["Alpha is invalid"])

              values = attribute_objects.values

              expect(values.map(&:column_name)).to eql %i[alpha beta]
              expect(values.map(&:value)).to eql [nil,  "beta :: - :: beta"]
              expect(values.map(&:source_value)).to eql %w[alpha beta]
              expect(values.map(&:parsed_value)).to eql ["alpha :: - :: alpha", "beta :: - :: beta"]
              expect(values.map(&:attribute_errors)).to eql [["is invalid"], []]
            end
          end
        end

        describe "#formatted_attributes" do
          subject(:formatted_attributes) { instance.formatted_attributes }

          let(:row_model_class) do
            Class.new(super()) do
              def self.format_cell(*args)
                args.join("__")
              end
            end
          end

          it "returns the formatted_headers" do
            expect(formatted_attributes).to eql(alpha: "alpha__alpha__#<OpenStruct>", beta: "beta__beta__#<OpenStruct>")
          end
        end
      end

      describe "class" do
        let(:row_model_class) do
          Class.new do
            include Csvbuilder::Model
            include Csvbuilder::Import
          end
        end

        describe ":column" do
          it_behaves_like "column_method", Csvbuilder::Import, alpha: "alpha", beta: "beta"
        end

        describe "::define_attribute_method" do
          subject(:define_attribute_method) { row_model_class.send(:define_attribute_method, :whatever) }

          it "makes an attribute that calls original_attribute" do
            define_attribute_method
            allow(instance).to receive(:original_attribute).with(:whatever).and_return("tested")
            expect(instance.whatever).to eql "tested"
          end

          context "with another validation added" do
            it_behaves_like "define_attribute_method"
          end
        end
      end
    end
  end
end
