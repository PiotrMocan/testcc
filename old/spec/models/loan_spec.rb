require 'spec_helper'

RSpec.describe Loan do
  let(:valid_attributes) do
    {
      id: 'LOAN_001',
      book_isbn: '9780132350884',
      member_id: 'MEM001',
      checkout_date: Time.new(2023, 6, 1, 12, 0, 0)
    }
  end

  subject { described_class.new(**valid_attributes) }

  it_behaves_like "a valid model"

  describe 'constants' do
    it 'has correct late fee per day' do
      expect(described_class::LATE_FEE_PER_DAY).to eq(10.0)
    end

    it 'has correct borrowing period' do
      expect(described_class::BORROWING_PERIOD_DAYS).to eq(14)
    end
  end

  describe '#initialize' do
    context 'with valid attributes' do
      it 'creates a loan with all attributes' do
        expect(subject.id).to eq('LOAN_001')
        expect(subject.book_isbn).to eq('9780132350884')
        expect(subject.member_id).to eq('MEM001')
        expect(subject.checkout_date).to eq(Time.new(2023, 6, 1, 12, 0, 0))
        expect(subject.due_date).to eq(Time.new(2023, 6, 15, 12, 0, 0))
        expect(subject.return_date).to be_nil
      end

      it 'uses current time as default checkout date' do
        loan = described_class.new(**valid_attributes.except(:checkout_date))
        expect(loan.checkout_date).to be_within(1).of(Time.now)
      end

      it 'accepts checkout date as string' do
        loan = described_class.new(**valid_attributes.merge(checkout_date: '2023-06-01'))
        expect(loan.checkout_date.year).to eq(2023)
        expect(loan.checkout_date.month).to eq(6)
        expect(loan.checkout_date.day).to eq(1)
      end

      it 'calculates due date correctly' do
        expected_due = valid_attributes[:checkout_date] + (14 * 24 * 60 * 60)
        expect(subject.due_date).to eq(expected_due)
      end
    end

    context 'with invalid attributes' do
      it 'raises error for empty ID' do
        expect {
          described_class.new(**valid_attributes.merge(id: ''))
        }.to raise_error(ArgumentError, "ID cannot be empty")
      end

      it 'raises error for nil ID' do
        expect {
          described_class.new(**valid_attributes.merge(id: nil))
        }.to raise_error(ArgumentError, "ID cannot be empty")
      end

      it 'raises error for empty book ISBN' do
        expect {
          described_class.new(**valid_attributes.merge(book_isbn: ''))
        }.to raise_error(ArgumentError, "Book ISBN cannot be empty")
      end

      it 'raises error for empty member ID' do
        expect {
          described_class.new(**valid_attributes.merge(member_id: ''))
        }.to raise_error(ArgumentError, "Member ID cannot be empty")
      end
    end
  end

  describe '#return_book' do
    let(:return_time) { Time.new(2023, 6, 10, 12, 0, 0) }

    it 'sets return date' do
      subject.return_book(return_time)
      expect(subject.return_date).to eq(return_time)
    end

    it 'uses current time by default' do
      subject.return_book
      expect(subject.return_date).to be_within(1).of(Time.now)
    end

    it 'accepts return date as string' do
      subject.return_book('2023-06-10')
      expect(subject.return_date.year).to eq(2023)
      expect(subject.return_date.month).to eq(6)
      expect(subject.return_date.day).to eq(10)
    end
  end

  describe '#active?' do
    it 'returns true when return date is nil' do
      expect(subject.active?).to be true
    end

    it 'returns false when return date is set' do
      subject.return_book
      expect(subject.active?).to be false
    end
  end

  describe '#overdue?' do
    let(:current_date) { Time.new(2023, 6, 20, 12, 0, 0) }

    context 'when loan is active and past due date' do
      it 'returns true' do
        expect(subject.overdue?(current_date)).to be true
      end
    end

    context 'when loan is active but not past due date' do
      let(:early_date) { Time.new(2023, 6, 10, 12, 0, 0) }
      
      it 'returns false' do
        expect(subject.overdue?(early_date)).to be false
      end
    end

    context 'when loan is returned' do
      it 'returns false even if was overdue' do
        subject.return_book(current_date)
        expect(subject.overdue?(current_date)).to be false
      end
    end

    it 'uses current time by default' do
      # This ensures the method works without explicitly passing time
      expect(subject.overdue?).to be_a(TrueClass).or be_a(FalseClass)
    end
  end

  describe '#days_overdue' do
    let(:current_date) { Time.new(2023, 6, 20, 12, 0, 0) }

    context 'when loan is overdue' do
      it 'calculates days overdue correctly' do
        expect(subject.days_overdue(current_date)).to eq(5)
      end

      it 'rounds up partial days' do
        partial_day = Time.new(2023, 6, 15, 18, 0, 0)
        expect(subject.days_overdue(partial_day)).to eq(1)
      end
    end

    context 'when loan is not overdue' do
      let(:early_date) { Time.new(2023, 6, 10, 12, 0, 0) }
      
      it 'returns 0' do
        expect(subject.days_overdue(early_date)).to eq(0)
      end
    end

    context 'when loan is returned' do
      it 'returns 0 even if was overdue' do
        subject.return_book(current_date)
        expect(subject.days_overdue(current_date)).to eq(0)
      end
    end
  end

  describe '#late_fee' do
    let(:current_date) { Time.new(2023, 6, 20, 12, 0, 0) }

    context 'when loan is overdue' do
      it 'calculates late fee correctly' do
        expected_fee = 5 * described_class::LATE_FEE_PER_DAY
        expect(subject.late_fee(current_date)).to eq(expected_fee)
      end
    end

    context 'when loan is not overdue' do
      let(:early_date) { Time.new(2023, 6, 10, 12, 0, 0) }
      
      it 'returns 0' do
        expect(subject.late_fee(early_date)).to eq(0)
      end
    end

    context 'when loan is returned' do
      it 'returns 0 even if was overdue' do
        subject.return_book(current_date)
        expect(subject.late_fee(current_date)).to eq(0)
      end
    end
  end

  describe '#to_hash and .from_hash' do
    before { subject.return_book(Time.new(2023, 6, 10)) }

    it 'serializes to hash correctly' do
      hash = subject.to_hash
      
      expect(hash).to include(
        id: 'LOAN_001',
        book_isbn: '9780132350884',
        member_id: 'MEM001'
      )
      expect(hash[:checkout_date]).to be_a(String)
      expect(hash[:due_date]).to be_a(String)
      expect(hash[:return_date]).to be_a(String)
    end

    it 'deserializes from hash correctly' do
      hash = subject.to_hash
      restored_loan = described_class.from_hash(hash)
      
      expect(restored_loan.id).to eq(subject.id)
      expect(restored_loan.book_isbn).to eq(subject.book_isbn)
      expect(restored_loan.member_id).to eq(subject.member_id)
      expect(restored_loan.checkout_date).to be_within(1).of(subject.checkout_date)
      expect(restored_loan.due_date).to be_within(1).of(subject.due_date)
      expect(restored_loan.return_date).to be_within(1).of(subject.return_date)
    end

    it 'handles nil return date' do
      subject.return_date = nil
      hash = subject.to_hash
      restored_loan = described_class.from_hash(hash)
      
      expect(restored_loan.return_date).to be_nil
    end

    it 'handles string keys from JSON' do
      hash = {
        'id' => 'LOAN_001',
        'book_isbn' => '9780132350884',
        'member_id' => 'MEM001',
        'checkout_date' => '2023-06-01',
        'due_date' => '2023-06-15',
        'return_date' => nil
      }
      
      restored_loan = described_class.from_hash(hash)
      expect(restored_loan.id).to eq('LOAN_001')
      expect(restored_loan.return_date).to be_nil
    end
  end
end