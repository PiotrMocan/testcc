require_relative '../../lib/modules/validator'

RSpec.describe Validator do
  describe '.valid_email?' do
    context 'with valid emails' do
      it 'returns true for standard email format' do
        expect(Validator.valid_email?('user@example.com')).to be true
      end

      it 'returns true for email with subdomain' do
        expect(Validator.valid_email?('user@mail.example.com')).to be true
      end

      it 'returns true for email with plus sign' do
        expect(Validator.valid_email?('user+tag@example.com')).to be true
      end

      it 'returns true for email with dots and hyphens' do
        expect(Validator.valid_email?('first.last-name@sub-domain.example.org')).to be true
      end
    end

    context 'with invalid emails' do
      it 'returns false for nil' do
        expect(Validator.valid_email?(nil)).to be false
      end

      it 'returns false for empty string' do
        expect(Validator.valid_email?('')).to be false
      end

      it 'returns false for email without @' do
        expect(Validator.valid_email?('userexample.com')).to be false
      end

      it 'returns false for email without domain' do
        expect(Validator.valid_email?('user@')).to be false
      end

      it 'returns false for email without local part' do
        expect(Validator.valid_email?('@example.com')).to be false
      end

      it 'returns false for email with spaces' do
        expect(Validator.valid_email?('user @example.com')).to be false
      end
    end
  end

  describe '.valid_isbn?' do
    context 'with valid ISBN-10' do
      it 'returns true for valid ISBN-10 with check digit' do
        expect(Validator.valid_isbn?('0306406152')).to be true
      end

      it 'returns true for valid ISBN-10 with X check digit' do
        expect(Validator.valid_isbn?('043942089X')).to be true
      end

      it 'returns true for ISBN-10 with hyphens' do
        expect(Validator.valid_isbn?('0-306-40615-2')).to be true
      end

      it 'returns true for ISBN-10 with spaces' do
        expect(Validator.valid_isbn?('0 306 40615 2')).to be true
      end
    end

    context 'with valid ISBN-13' do
      it 'returns true for valid ISBN-13' do
        expect(Validator.valid_isbn?('9780306406157')).to be true
      end

      it 'returns true for ISBN-13 with hyphens' do
        expect(Validator.valid_isbn?('978-0-306-40615-7')).to be true
      end
    end

    context 'with invalid ISBNs' do
      it 'returns false for nil' do
        expect(Validator.valid_isbn?(nil)).to be false
      end

      it 'returns false for empty string' do
        expect(Validator.valid_isbn?('')).to be false
      end

      it 'returns false for wrong length' do
        expect(Validator.valid_isbn?('123456789')).to be false
        expect(Validator.valid_isbn?('12345678901234')).to be false
      end

      it 'returns false for invalid ISBN-10 check digit' do
        expect(Validator.valid_isbn?('0306406153')).to be false
      end

      it 'returns false for invalid ISBN-13 check digit' do
        expect(Validator.valid_isbn?('9780306406158')).to be false
      end

      it 'returns false for non-numeric characters (except X)' do
        expect(Validator.valid_isbn?('030640615A')).to be false
      end
    end
  end
end