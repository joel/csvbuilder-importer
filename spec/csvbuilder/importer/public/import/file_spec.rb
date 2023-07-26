# frozen_string_literal: true

require "spec_helper"

module Csvbuilder
  module Import
    RSpec.describe File do
      let(:file_path)       { basic_1_row_path }
      let(:row_model_class) { BasicImportModel }
      let(:file_class)      { described_class }
      let(:instance)        { file_class.new file_path, row_model_class, "some_context" => true }

      describe "#context" do
        it "symbolizes the context" do
          expect(instance.context[:some_context]).to be true
        end
      end

      describe "#headers" do
        subject(:headers) { instance.headers }

        it "returns the headers" do
          expect(headers).to eql %w[alpha beta]
        end

        context "with bad header" do
          let(:file_path) { bad_headers_1_row_path }

          it "has header to be an empty array" do
            expect(instance.headers).to eql []
          end
        end
      end

      describe "#reset" do
        subject(:reset) { instance.reset }

        context "when at the end of the file" do
          before { while instance.next; end }

          it "resets and starts at the first row" do
            reset
            expect(instance.index).to be(-1)
            expect(instance.line_number).to be 0
            expect(instance.current_row_model).to be_nil
            expect(instance.next.source_row).to eql %w[lang1 lang2]
          end
        end
      end

      describe "#next" do
        subject(:next_row) { instance.next }

        let(:file_path) { basic_5_rows_path }

        context "when passing a context" do
          subject(:next_row) { instance.next("another_context" => true) }

          it "merges contexts" do
            expect(next_row.context).to eql OpenStruct.new(some_context: true, another_context: true)
          end

          it "symbolizes the context in an OpenStruct" do
            expect(next_row.context[:another_context]).to be true
          end
        end

        it "gets the rows until the end of file" do
          current_row_model = nil

          5.times do |index|
            previous_row_model = current_row_model
            current_row_model  = instance.next

            expect(current_row_model.class).to eql row_model_class

            expect(current_row_model.source_row).to eql %W[firsts#{index} seconds#{index}]

            expect(current_row_model.previous.try(:source_row)).to eql previous_row_model.try(:source_row)
            expect(current_row_model.index).to eql index

            # header means +1, starts at 1 means +1 too--- 1 + 1 = 2
            expect(current_row_model.line_number).to eql index + 2
            expect(current_row_model.context).to eql OpenStruct.new(some_context: true)
          end

          3.times do
            expect(instance.next).to be_nil
            expect(instance.end_of_file?).to be true
          end
        end

        context "with badly formatted file" do
          let(:file_path) { syntax_bad_quotes_5_rows_path }

          it "returns invalid row" do
            row = instance.next
            expect(row).to be_valid
            expect(row.source_row).to eql %w[alpha beta]

            invalid_row = instance.next
            expect(invalid_row).to be_invalid
            expect(invalid_row.errors.full_messages).to eql ["Csv has Any value after quoted field isn't allowed in line 3."]
            expect(invalid_row.source_row).to eql []

            row = instance.next
            expect(row).to be_valid
            expect(row.source_row).to eql %w[lang1 lang2]

            expect(instance.next).to be_invalid
            expect(instance.next).to be_invalid
            expect(instance.next).to be_nil
          end
        end
      end

      describe "#each" do
        subject(:each_row) { instance.each }

        context "with abort from row model" do
          before { allow(instance).to receive(:abort?).and_return(true) }

          it "never yields and call callbacks" do
            allow(instance).to receive(:run_callbacks).with(:abort).once

            expect { each_row.next }.to raise_error(StopIteration)
          end
        end

        context "with abort from file importer" do
          before { instance.abort! }

          it "never yields and call callbacks" do
            allow(instance).to receive(:run_callbacks).with(:abort).once

            expect { each_row.next }.to raise_error(StopIteration)
          end
        end

        context "with abort on third row_model" do
          let(:file_path) { basic_5_rows_path }
          let(:row_model_class) do
            Class.new(BasicImportModel) do
              def abort?
                source_row.last.ends_with? "2"
              end

              def self.name
                "BasicImportModelWithAbort"
              end
            end
          end

          it "yields twice and call callbacks" do
            allow(instance).to receive(:run_callbacks).with(anything).and_call_original
            allow(instance).to receive(:run_callbacks).with(:abort).and_call_original.once

            each_row.next
            each_row.next
            expect { each_row.next }.to raise_error(StopIteration)
          end
        end

        context "with skips on even rows" do
          let(:file_path) { basic_5_rows_path }
          let(:row_model_class) do
            Class.new(BasicImportModel) do
              def skip?
                source_row.last.last.to_i.odd?
              end

              def self.name
                "BasicImportModelWithSkip"
              end
            end
          end

          it "skips twice" do
            allow(instance).to receive(:run_callbacks).with(anything).and_call_original
            allow(instance).to receive(:run_callbacks).with(:skip).and_call_original.twice

            each_row.next
            each_row.next
            each_row.next
            expect { each_row.next }.to raise_error(StopIteration)
          end
        end
      end

      describe "#valid?" do
        subject(:valid_file) { instance.valid? }

        it "defaults to true" do
          expect(valid_file).to be true
        end

        context "with bad file path" do
          let(:file_path) { "abc" }

          it "passes CSV errors to the errors" do
            expect(valid_file).to be false
            expect(instance.errors.full_messages).to eql ["Csv No such file or directory @ rb_sysopen - abc"]
          end
        end
      end

      describe "#abort?" do
        subject(:abort_file) { instance.abort? }

        context "when valid?" do
          before do
            allow(instance).to receive(:valid?).and_return(true)
          end

          context "when current_row_model is nil" do
            before do
              allow(instance).to receive(:current_row_model).and_return(nil)
            end

            it "returns false" do
              expect(abort_file).to be false
            end
          end
        end
      end

      describe "#skip?" do
        subject(:skip_file) { instance.skip? }

        context "when current_row_model is nil" do
          before do
            allow(instance).to receive(:current_row_model).and_return(nil)
          end

          it "returns false" do
            expect(skip_file).to be false
          end
        end
      end

      describe "#headers_invalid_row" do
        subject(:valid_file) { instance.valid? }

        let(:file_class) do
          Class.new(described_class) do
            validate :headers_invalid_row
            def self.name
              "Test" end
          end
        end

        it "is valid when header is valid" do
          expect(valid_file).to be true
        end

        context "with bad header" do
          let(:file_path) { bad_headers_1_row_path }

          it "is false and calls #headers_invalid_row" do
            expect(valid_file).to be false
            expect(instance.errors.full_messages).to eql ["Csv has header with Unclosed quoted field in line 1."]
          end
        end
      end

      describe "#headers_count" do
        subject(:valid_file) { instance.valid? }

        let(:file_class) do
          Class.new(described_class) do
            validate :headers_count
            def self.name
              "Test" end
          end
        end

        context "with mixed empty headers" do
          let(:file_path) { headers_with_mixed_empty_1_row_path }

          it "is invalid" do
            expect(valid_file).to be false
          end
        end

        context "with empty header" do
          let(:file_path) { empty_headers_1_row_path }

          it "is invalid with a nice message" do
            expect(valid_file).to be false
            expect(instance.errors.full_messages).to eql ["Headers count does not match. Given headers (0). Expected headers (2): alpha, beta"]
          end
        end
      end
    end
  end
end
