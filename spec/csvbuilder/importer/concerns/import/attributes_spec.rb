# frozen_string_literal: true

require "spec_helper"

module Csvbuilder
  module Import
    RSpec.describe Attributes do
      let(:row_model_class) { Class.new BasicImportModel }
      let(:source_row)      { %w[alpha beta] }
      let(:instance)        { row_model_class.new(source_row) }

      describe "instance" do
        describe "define methods" do
          it { expect(instance).to respond_to(:alpha) }
        end

        describe "#attribute_objects" do
          subject(:attribute_objects) { instance.attribute_objects }

          it "returns a hash of cells mapped to their column_name" do
            expect(attribute_objects.keys).to eql row_model_class.column_names
            expect(attribute_objects.values.map(&:class)).to eql [Csvbuilder::Import::Attribute] * 2
          end

          context "when invalid and invalid parsed_model" do
            let(:row_model_class) do
              Class.new(BasicImportModel) do
                validates :alpha, presence: true
              end
            end
            let(:source_row) { [] }

            it "returns the cells with the right attributes" do
              values = attribute_objects.values

              expect(values.map(&:column_name)).to eql %i[alpha beta]
              expect(values.map(&:source_value)).to eql [nil, nil]
              # expect(values.map(&:attribute_errors)).to eql [[], ["can't be blank"]]
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
