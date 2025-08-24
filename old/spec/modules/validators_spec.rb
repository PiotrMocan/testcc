require 'spec_helper'

RSpec.describe Validators do
  let(:test_class) do
    Class.new do
      include Validators
    end
  end
  let(:validator) { test_class.new }

  describe '#valid_email?' do
    context 'with valid emails' do
      it 'accepts standard email format' do
        expect(validator.valid_email?('user@example.com')).to be true
      end

      it 'accepts email with dots in username' do
        expect(validator.valid_email?('user.name@example.com')).to be true
      end

      it 'accepts email with plus sign' do
        expect(validator.valid_email?('user+tag@example.com')).to be true
      end

      it 'accepts email with numbers' do
        expect(validator.valid_email?('user123@example123.com')).to be true
      end

      it 'accepts email with subdomain' do
        expect(validator.valid_email?('user@mail.example.com')).to be true
      end
    end

    context 'with invalid emails' do
      it 'rejects email without @ symbol' do
        expect(validator.valid_email?('userexample.com')).to be false
      end

      it 'rejects email without domain' do
        expect(validator.valid_email?('user@')).to be false
      end

      it 'rejects email without username' do
        expect(validator.valid_email?('@example.com')).to be false
      end

      it 'rejects email with spaces' do
        expect(validator.valid_email?('user @example.com')).to be false
      end

      it 'rejects nil email' do
        expect(validator.valid_email?(nil)).to be false
      end

      it 'rejects empty email' do
        expect(validator.valid_email?('')).to be false
      end

      it 'rejects email with invalid TLD' do
        expect(validator.valid_email?('user@example.c')).to be false
      end
    end
  end

  describe '#valid_isbn?' do
    context 'with valid ISBN-10' do
      it 'accepts valid ISBN-10 with check digit' do
        expect(validator.valid_isbn?('0132350882')).to be true
      end

      it 'accepts valid ISBN-10 with X check digit' do
        expect(validator.valid_isbn?('043942089X')).to be true
      end

      it 'accepts ISBN-10 with dashes' do
        expect(validator.valid_isbn?('0-13-235088-2')).to be true
      end

      it 'accepts ISBN-10 with spaces' do
        expect(validator.valid_isbn?('0 13 235088 2')).to be true
      end
    end

    context 'with valid ISBN-13' do
      it 'accepts valid ISBN-13' do
        expect(validator.valid_isbn?('9780132350884')).to be true
      end

      it 'accepts ISBN-13 with dashes' do
        expect(validator.valid_isbn?('978-0-13-235088-4')).to be true
      end

      it 'accepts ISBN-13 with spaces' do
        expect(validator.valid_isbn?('978 0 13 235088 4')).to be true
      end
    end

    context 'with invalid ISBNs' do
      it 'rejects invalid ISBN-10 check digit' do
        expect(validator.valid_isbn?('0132350881')).to be false
      end

      it 'rejects invalid ISBN-13 check digit' do
        expect(validator.valid_isbn?('9780132350883')).to be false
      end

      it 'rejects ISBN with wrong length' do
        expect(validator.valid_isbn?('123456789')).to be false
      end

      it 'rejects ISBN with letters (except X in ISBN-10)' do
        expect(validator.valid_isbn?('013235088A')).to be false
      end

      it 'rejects nil ISBN' do
        expect(validator.valid_isbn?(nil)).to be false
      end

      it 'rejects empty ISBN' do
        expect(validator.valid_isbn?('')).to be false
      end

      it 'rejects ISBN with special characters' do
        expect(validator.valid_isbn?('0132350881!')).to be false
      end
    end
  end
end