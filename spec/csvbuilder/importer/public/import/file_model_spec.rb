# frozen_string_literal: true

require "spec_helper"

module Csvbuilder
  module Import
    RSpec.describe FileModel do
      let(:context) { {} }

      describe "class" do
        let(:import_model_klass) { FileImportModel }

        describe "#header_matchers" do
          subject(:header_matchers) { import_model_klass.header_matchers(context) }

          let(:expected_header_matchers) { [/^HEADER <- alpha -> HEADER$/i, /^HEADER <- beta -> HEADER$/i] }

          it { expect(header_matchers).to eql expected_header_matchers }
        end

        describe "#index_header_match" do
          context "when is a match" do
            subject(:index_header_match) { import_model_klass.index_header_match(some_cell, context) }

            let(:some_cell) { "HEADER <- alpha -> HEADER" }

            it { expect(index_header_match).to be_truthy }
            it { expect(index_header_match).to be 0 } # position of the header
          end

          context "when is not a match" do
            subject(:index_header_match) { import_model_klass.index_header_match(some_cell, context) }

            let(:some_cell) { "String 3" }

            it { expect(index_header_match).to be_nil }
          end
        end
      end
    end
  end
end
