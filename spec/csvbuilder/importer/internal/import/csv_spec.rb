# frozen_string_literal: true

require "spec_helper"

module Csvbuilder
  module Import
    RSpec.describe Csv do
      let(:file_path) { basic_1_row_path }
      let(:instance)  { described_class.new(file_path) }

      describe "#valid?" do
        subject(:import_valid) { instance.valid? }

        it "defaults to true" do
          expect(import_valid).to be true
        end

        context "with bad file path" do
          let(:file_path) { "abc" }

          it "returns false" do
            expect(import_valid).to be false
            expect(instance.errors.full_messages).to eql ["Csv No such file or directory @ rb_sysopen - abc"]
          end
        end
      end

      describe "#size" do
        subject(:size) { instance.size }

        it "returns the correct size" do
          expect(size).to be 2
        end

        context "with empty lines" do
          let(:file_path) { syntax_empty_5_rows_path }

          it "counts the empty lines" do
            expect(size).to be 6
          end
        end
      end

      def start_of_file?(instance)
        expect(instance.line_number).to be 0
        expect(instance.current_row).to be_nil
      end

      def first_row?(instance)
        expect(instance.line_number).to be 1
        expect(instance.current_row).to eql %w[alpha beta]
      end

      describe "#skip_headers" do
        subject(:skip_headers) { instance.skip_headers }

        it "goes to the second row and doesn't move" do
          start_of_file? instance

          expect(instance.skip_headers).to eql %w[alpha beta]
          expect(instance.skip_headers).to be false

          first_row? instance
        end

        it "works when header is called" do
          start_of_file? instance

          instance.headers
          expect(skip_headers).to eql %w[alpha beta]

          first_row? instance
        end
      end

      describe "#headers" do
        subject(:headers) { instance.headers }

        it "returns the header without changing the state" do
          start_of_file? instance

          expect(headers).to eql %w[alpha beta]

          start_of_file? instance
        end

        context "with bad header syntax" do
          let(:file_path) { bad_headers_1_row_path }

          it "returns an exception" do
            expect(headers.to_s).to eql "Unclosed quoted field in line 1."
          end
        end
      end

      describe "#reset" do
        subject(:reset) { instance.reset }

        it "sets the state back to reset" do
          expect(instance.read_row).to eql %w[alpha beta]
          expect(instance.next_row).to eql %w[lang1 lang2]
          first_row? instance
          expect(reset).to be true
          start_of_file? instance
          expect(instance.read_row).to eql %w[alpha beta]
        end
      end

      describe "#start_of_file?" do
        subject(:start_of_file) { instance.start_of_file? }

        it do
          expect(start_of_file).to be true
        end
      end

      describe "#end_of_file?" do
        subject(:end_of_file) { instance.end_of_file? }

        it do
          while instance.read_row; end
          expect(end_of_file).to be true
        end
      end

      describe "#next_row" do
        subject(:next_row) { instance.next_row }

        it "returns the next row without changing the state" do
          start_of_file? instance

          expect(next_row).to eql %w[alpha beta]
          expect(next_row).to eql %w[alpha beta]

          start_of_file? instance

          expect(instance.read_row).to eql %w[alpha beta]
        end

        it "sets allows the header to be available" do
          next_row
          expect(instance.headers).to eql %w[alpha beta]
        end
      end

      describe "#read_row" do
        subject(:read_row) { instance.read_row }

        it "works and goes to end of file" do
          expect(instance.read_row).to eql %w[alpha beta]
          expect(instance.read_row).to eql %w[lang1 lang2]
          expect(instance.read_row).to be_nil
          expect(instance.read_row).to be_nil
          expect(instance.end_of_file?).to be true
        end

        it "sets allows the header to be available" do
          read_row
          expect(instance.headers).to eql %w[alpha beta]
        end

        context "with empty lines" do
          let(:file_path) { syntax_empty_5_rows_path }

          it "just returns an empty array" do
            expect(instance.read_row).to eql []
            expect(instance.line_number).to be 1

            expect(instance.read_row).to eql %w[alpha beta]
            expect(instance.line_number).to be 2
          end
        end

        context "with bad quotes row and and tracks skipped_rows" do
          let(:file_path) { syntax_bad_quotes_5_rows_path }

          it "returns the exception" do
            expect(instance.read_row.to_s).to eql "Illegal quoting in line 1."
            expect(instance.line_number).to be 1

            expect(instance.read_row).to eql %w[alpha beta]
            expect(instance.line_number).to be 2

            expect(instance.read_row.to_s).to eql "Any value after quoted field isn't allowed in line 3."
            expect(instance.line_number).to be 3

            expect(instance.read_row).to eql %w[lang1 lang2]
            expect(instance.line_number).to be 4

            expect(instance.read_row.to_s).to eql "Illegal quoting in line 5."
            expect(instance.line_number).to be 5

            expect(instance.read_row.to_s).to eql "Unclosed quoted field in line 6."
            expect(instance.line_number).to be 6

            expect(instance.read_row).to be_nil
          end
        end
      end
    end
  end
end
