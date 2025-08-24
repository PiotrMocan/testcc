require_relative '../../lib/models/loan'
require_relative '../shared_examples'
require 'date'

RSpec.describe Loan do
  let(:valid_attributes) do
    {
      book_isbn: '9780306406157',
      member_id: 'member-123'
    }
  end

  let(:expected_hash_keys) { [:id, :book_isbn, :member_id, :checkout_date, :due_date, :return_date, :late_fee] }

  describe 'initialization' do
    it 'creates a loan with valid attributes' do
      loan = Loan.new(**valid_attributes)
      expect(loan.book_isbn).to eq('9780306406157')
      expect(loan.member_id).to eq('member-123')
      expect(loan.id).to be_a(String)
      expect(loan.checkout_date).to eq(Date.today)
      expect(loan.due_date).to eq(Date.today + 14)
      expect(loan.return_date).to be_nil
      expect(loan.late_fee).to eq(0)
    end

    it 'accepts custom checkout date' do
      custom_date = Date.new(2023, 1, 1)
      loan = Loan.new(**valid_attributes.merge(checkout_date: custom_date))
      expect(loan.checkout_date).to eq(custom_date)
      expect(loan.due_date).to eq(custom_date + 14)
    end

    it 'accepts custom ID' do
      loan = Loan.new(**valid_attributes.merge(id: 'custom-id'))
      expect(loan.id).to eq('custom-id')
    end

    it 'accepts string dates' do
      loan = Loan.new(**valid_attributes.merge(checkout_date: '2023-01-01'))
      expect(loan.checkout_date).to eq(Date.new(2023, 1, 1))
    end

    it 'validates book_isbn presence' do
      expect {
        Loan.new(**valid_attributes.merge(book_isbn: nil))
      }.to raise_error(ArgumentError, "Book ISBN cannot be empty")

      expect {
        Loan.new(**valid_attributes.merge(book_isbn: ''))
      }.to raise_error(ArgumentError, "Book ISBN cannot be empty")
    end

    it 'validates member_id presence' do
      expect {
        Loan.new(**valid_attributes.merge(member_id: nil))
      }.to raise_error(ArgumentError, "Member ID cannot be empty")

      expect {
        Loan.new(**valid_attributes.merge(member_id: ''))
      }.to raise_error(ArgumentError, "Member ID cannot be empty")
    end

    it 'strips whitespace from string attributes' do
      loan = Loan.new(
        book_isbn: '  9780306406157  ',
        member_id: '  member-123  '
      )
      expect(loan.book_isbn).to eq('9780306406157')
      expect(loan.member_id).to eq('member-123')
    end
  end

  describe '#return_book' do
    let(:loan) { Loan.new(**valid_attributes) }

    it 'sets return date' do
      return_date = Date.today + 1
      loan.return_book(return_date)
      expect(loan.return_date).to eq(return_date)
    end

    it 'accepts string return date' do
      loan.return_book('2023-01-15')
      expect(loan.return_date).to eq(Date.new(2023, 1, 15))
    end

    it 'defaults to today if no date provided' do
      loan.return_book
      expect(loan.return_date).to eq(Date.today)
    end

    it 'calculates late fee on return' do
      overdue_loan = Loan.new(**valid_attributes.merge(checkout_date: Date.today - 20))
      overdue_loan.return_book(Date.today)
      expect(overdue_loan.late_fee).to eq(60) # 6 days overdue * 10 rubles
    end

    it 'raises error if book already returned' do
      loan.return_book
      expect { loan.return_book }.to raise_error(StandardError, "Book already returned")
    end
  end

  describe '#overdue?' do
    it 'returns false for current loan' do
      loan = Loan.new(**valid_attributes)
      expect(loan.overdue?).to be false
    end

    it 'returns true for overdue loan' do
      overdue_loan = Loan.new(**valid_attributes.merge(checkout_date: Date.today - 20))
      expect(overdue_loan.overdue?).to be true
    end

    it 'returns false for returned books' do
      overdue_loan = Loan.new(**valid_attributes.merge(checkout_date: Date.today - 20))
      overdue_loan.return_book
      expect(overdue_loan.overdue?).to be false
    end

    it 'accepts custom current date' do
      loan = Loan.new(**valid_attributes.merge(checkout_date: Date.new(2023, 1, 1)))
      expect(loan.overdue?(Date.new(2023, 1, 20))).to be true
    end
  end

  describe '#days_overdue' do
    it 'returns 0 for current loans' do
      loan = Loan.new(**valid_attributes)
      expect(loan.days_overdue).to eq(0)
    end

    it 'calculates days overdue correctly' do
      overdue_loan = Loan.new(**valid_attributes.merge(checkout_date: Date.today - 20))
      expect(overdue_loan.days_overdue).to eq(6) # 20 - 14 = 6 days overdue
    end

    it 'returns 0 for returned books' do
      overdue_loan = Loan.new(**valid_attributes.merge(checkout_date: Date.today - 20))
      overdue_loan.return_book
      expect(overdue_loan.days_overdue).to eq(0)
    end
  end

  describe '#calculate_late_fee' do
    it 'returns 0 for current loans' do
      loan = Loan.new(**valid_attributes)
      expect(loan.calculate_late_fee).to eq(0)
    end

    it 'calculates fee for overdue loans' do
      overdue_loan = Loan.new(**valid_attributes.merge(checkout_date: Date.today - 20))
      expect(overdue_loan.calculate_late_fee).to eq(60) # 6 days * 10 rubles
    end

    it 'returns existing fee for returned books' do
      overdue_loan = Loan.new(**valid_attributes.merge(checkout_date: Date.today - 20))
      overdue_loan.return_book
      expect(overdue_loan.calculate_late_fee).to eq(overdue_loan.late_fee)
    end
  end

  describe 'status methods' do
    let(:loan) { Loan.new(**valid_attributes) }

    describe '#returned?' do
      it 'returns false for active loans' do
        expect(loan.returned?).to be false
      end

      it 'returns true for returned loans' do
        loan.return_book
        expect(loan.returned?).to be true
      end
    end

    describe '#active?' do
      it 'returns true for active loans' do
        expect(loan.active?).to be true
      end

      it 'returns false for returned loans' do
        loan.return_book
        expect(loan.active?).to be false
      end
    end
  end

  it_behaves_like "a persistable object", Loan

  describe 'equality and hashing' do
    let(:loan1) { Loan.new(**valid_attributes.merge(id: 'same-id')) }
    let(:loan2) { Loan.new(**valid_attributes.merge(id: 'same-id')) }
    let(:different_loan) { Loan.new(**valid_attributes.merge(id: 'different-id')) }

    it 'treats loans with same ID as equal' do
      expect(loan1).to eq(loan2)
      expect(loan1.eql?(loan2)).to be true
    end

    it 'treats loans with different ID as not equal' do
      expect(loan1).not_to eq(different_loan)
    end

    it 'has consistent hash values for equal objects' do
      expect(loan1.hash).to eq(loan2.hash)
    end
  end

  describe '#to_s' do
    let(:loan) { Loan.new(**valid_attributes) }

    it 'returns readable string for active loan' do
      expected = "Loan #{loan.id}: Book 9780306406157 to Member member-123, due #{loan.due_date}"
      expect(loan.to_s).to eq(expected)
    end

    it 'returns readable string for returned loan' do
      loan.return_book
      expected = "Loan #{loan.id}: Book 9780306406157 to Member member-123, returned on #{loan.return_date}"
      expect(loan.to_s).to eq(expected)
    end
  end
end