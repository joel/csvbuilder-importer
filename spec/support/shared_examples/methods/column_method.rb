# frozen_string_literal: true

shared_examples "column_method" do |mod, expectation = {}|
  context "when module included before and after #column call" do
    let(:row_model_class) { Class.new }

    before do
      row_model_class.send(:include, Csvbuilder::Model)
      row_model_class.send(:column, :alpha)
      row_model_class.send(:include, mod)
      row_model_class.send(:column, :beta)
    end

    it do
      expect(instance.alpha).to eql expectation[:alpha]
      expect(instance.beta).to  eql expectation[:beta]
    end

    context "with method defined before column" do
      let(:row_model_class) do
        Class.new do
          def alpha
            "custom1"
          end

          def beta
            "custom2"
          end
        end
      end

      it "does not override those methods" do
        expect(instance.alpha).to eql "custom1"
        expect(instance.beta).to eql "custom2"
      end
    end
  end
end
