# frozen_string_literal: true

require "spec_helper"

module Csvbuilder
  RSpec.describe Import do
    context "without including Csvbuilder::Model" do
      let(:klass) do
        Class.new do
          include Import

          column :alpha
          column :beta
        end
      end

      it do
        instance = klass.new(%w[alpha beta], source_headers: ["Alpha", "Beta"])
        expect(instance.attributes).to eql(alpha: "alpha", beta: "beta")
      end

      it "has Csvbuilder::Model included" do
        expect(klass.ancestors).to include Csvbuilder::Model
      end
    end
  end
end
