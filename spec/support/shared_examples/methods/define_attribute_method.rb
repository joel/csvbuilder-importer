# frozen_string_literal: true

shared_examples "define_attribute_method" do
  it "does not do anything the second time" do
    allow(row_model_class).to receive(:define_proxy_method).with(:whatever).once.and_call_original
    allow(row_model_class).to receive(:define_proxy_method).with(:whenever).once.and_call_original

    row_model_class.send(:define_attribute_method, :whatever)
    row_model_class.send(:define_attribute_method, :whatever)

    row_model_class.send(:define_attribute_method, :whenever)
    row_model_class.send(:define_attribute_method, :whenever)
  end
end
