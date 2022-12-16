# frozen_string_literal: true

shared_examples "has_needed_value_methods" do |mod = Csvbuilder::AttributesBase|
  mod::ATTRIBUTE_METHODS.each_value do |method_name|
    describe "##{method_name}" do
      subject { instance.public_send(method_name) }

      it "#attributes works" do
        expect(subject).not_to eql nil
      end
    end
  end
end
