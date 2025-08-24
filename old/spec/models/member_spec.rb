require 'spec_helper'

RSpec.describe Member do
  let(:valid_attributes) do
    {
      id: 'MEM001',
      name: 'John Doe',
      email: 'john.doe@example.com'
    }
  end

  subject { described_class.new(**valid_attributes) }

  it_behaves_like "a valid model"

  describe '#initialize' do
    context 'with valid attributes' do
      it 'creates a member with all attributes' do
        expect(subject.id).to eq('MEM001')
        expect(subject.name).to eq('John Doe')
        expect(subject.email).to eq('john.doe@example.com')
        expect(subject.registration_date).to be_a(Time)
        expect(subject.borrowing_history).to eq([])
      end

      it 'normalizes email to lowercase' do
        member = described_class.new(**valid_attributes.merge(email: 'John.DOE@EXAMPLE.COM'))
        expect(member.email).to eq('john.doe@example.com')
      end

      it 'strips whitespace from name and email' do
        member = described_class.new(
          **valid_attributes.merge(
            name: '  John Doe  ',
            email: '  john@example.com  '
          )
        )
        
        expect(member.name).to eq('John Doe')
        expect(member.email).to eq('john@example.com')
      end

      it 'accepts custom registration date as Time object' do
        custom_date = Time.new(2023, 1, 1)
        member = described_class.new(**valid_attributes.merge(registration_date: custom_date))
        expect(member.registration_date).to eq(custom_date)
      end

      it 'accepts custom registration date as string' do
        member = described_class.new(**valid_attributes.merge(registration_date: '2023-01-01'))
        expect(member.registration_date.year).to eq(2023)
        expect(member.registration_date.month).to eq(1)
        expect(member.registration_date.day).to eq(1)
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

      it 'raises error for empty name' do
        expect {
          described_class.new(**valid_attributes.merge(name: ''))
        }.to raise_error(ArgumentError, "Name cannot be empty")
      end

      it 'raises error for invalid email' do
        expect {
          described_class.new(**valid_attributes.merge(email: 'invalid-email'))
        }.to raise_error(ArgumentError, "Invalid email format")
      end
    end
  end

  describe '#add_to_history' do
    let(:loan_record) do
      {
        book_isbn: '9780132350884',
        checkout_date: Time.now,
        due_date: Time.now + (14 * 24 * 60 * 60),
        return_date: nil
      }
    end

    it 'adds loan record to borrowing history' do
      expect { subject.add_to_history(loan_record) }.to change { subject.borrowing_history.size }.by(1)
      expect(subject.borrowing_history).to include(loan_record)
    end
  end

  describe '#active_loans' do
    let(:active_loan) do
      {
        book_isbn: '9780132350884',
        checkout_date: Time.now - (7 * 24 * 60 * 60),
        due_date: Time.now + (7 * 24 * 60 * 60),
        return_date: nil
      }
    end

    let(:returned_loan) do
      {
        book_isbn: '9780321146533',
        checkout_date: Time.now - (21 * 24 * 60 * 60),
        due_date: Time.now - (7 * 24 * 60 * 60),
        return_date: Time.now - (5 * 24 * 60 * 60)
      }
    end

    before do
      subject.add_to_history(active_loan)
      subject.add_to_history(returned_loan)
    end

    it 'returns only loans without return date' do
      active = subject.active_loans
      expect(active.size).to eq(1)
      expect(active.first[:book_isbn]).to eq('9780132350884')
    end
  end

  describe '#overdue_loans' do
    let(:current_time) { Time.new(2023, 6, 15, 12, 0, 0) }
    
    let(:overdue_loan) do
      {
        book_isbn: '9780132350884',
        checkout_date: current_time - (21 * 24 * 60 * 60),
        due_date: current_time - (7 * 24 * 60 * 60),
        return_date: nil
      }
    end

    let(:on_time_loan) do
      {
        book_isbn: '9780321146533',
        checkout_date: current_time - (7 * 24 * 60 * 60),
        due_date: current_time + (7 * 24 * 60 * 60),
        return_date: nil
      }
    end

    before do
      subject.add_to_history(overdue_loan)
      subject.add_to_history(on_time_loan)
    end

    it 'returns only overdue active loans' do
      overdue = subject.overdue_loans(current_time)
      expect(overdue.size).to eq(1)
      expect(overdue.first[:book_isbn]).to eq('9780132350884')
    end

    it 'uses current time by default' do
      # This test ensures the method works without explicitly passing time
      expect(subject.overdue_loans).to be_an(Array)
    end
  end

  describe '#total_borrowed_books' do
    it 'returns total number of books borrowed' do
      expect(subject.total_borrowed_books).to eq(0)
      
      subject.add_to_history({ book_isbn: '123' })
      subject.add_to_history({ book_isbn: '456' })
      
      expect(subject.total_borrowed_books).to eq(2)
    end
  end

  describe '#to_hash and .from_hash' do
    let(:loan_history) do
      [
        {
          book_isbn: '9780132350884',
          checkout_date: Time.new(2023, 1, 1),
          due_date: Time.new(2023, 1, 15),
          return_date: Time.new(2023, 1, 10)
        }
      ]
    end

    before { subject.borrowing_history = loan_history }

    it 'serializes to hash correctly' do
      hash = subject.to_hash
      
      expect(hash).to include(
        id: 'MEM001',
        name: 'John Doe',
        email: 'john.doe@example.com',
        borrowing_history: loan_history
      )
      expect(hash[:registration_date]).to be_a(String)
    end

    it 'deserializes from hash correctly' do
      hash = subject.to_hash
      restored_member = described_class.from_hash(hash)
      
      expect(restored_member.id).to eq(subject.id)
      expect(restored_member.name).to eq(subject.name)
      expect(restored_member.email).to eq(subject.email)
      expect(restored_member.borrowing_history).to eq(subject.borrowing_history)
      expect(restored_member.registration_date).to be_a(Time)
    end

    it 'handles string keys from JSON' do
      hash = {
        'id' => 'MEM001',
        'name' => 'John Doe',
        'email' => 'john.doe@example.com',
        'registration_date' => '2023-01-01',
        'borrowing_history' => []
      }
      
      restored_member = described_class.from_hash(hash)
      expect(restored_member.id).to eq('MEM001')
      expect(restored_member.registration_date.year).to eq(2023)
    end
  end
end