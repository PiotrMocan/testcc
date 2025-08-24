require_relative '../../lib/models/member'
require_relative '../shared_examples'
require 'date'

RSpec.describe Member do
  let(:valid_attributes) do
    {
      name: 'John Doe',
      email: 'john.doe@example.com'
    }
  end

  let(:expected_hash_keys) { [:id, :name, :email, :registration_date, :borrowing_history] }

  describe 'initialization' do
    it 'creates a member with valid attributes' do
      member = Member.new(**valid_attributes)
      expect(member.name).to eq('John Doe')
      expect(member.email).to eq('john.doe@example.com')
      expect(member.id).to be_a(String)
      expect(member.registration_date).to eq(Date.today)
      expect(member.borrowing_history).to be_empty
    end

    it 'accepts custom ID' do
      member = Member.new(**valid_attributes.merge(id: 'custom-id'))
      expect(member.id).to eq('custom-id')
    end

    it 'strips whitespace and downcases email' do
      member = Member.new(
        name: '  John Doe  ',
        email: '  JOHN.DOE@EXAMPLE.COM  '
      )
      expect(member.name).to eq('John Doe')
      expect(member.email).to eq('john.doe@example.com')
    end

    it_behaves_like "validates presence of", :name

    it 'validates email format' do
      expect {
        Member.new(**valid_attributes.merge(email: 'invalid-email'))
      }.to raise_error(ArgumentError, "Invalid email format")
    end

    it 'validates email presence' do
      expect {
        Member.new(**valid_attributes.merge(email: nil))
      }.to raise_error(ArgumentError, "Invalid email format")
    end
  end

  describe 'borrowing history management' do
    let(:member) { Member.new(**valid_attributes) }
    let(:loan_record) do
      {
        book_isbn: '9780306406157',
        checkout_date: '2023-01-01',
        due_date: '2023-01-15',
        return_date: nil
      }
    end

    describe '#add_to_history' do
      it 'adds loan record to history' do
        expect { member.add_to_history(loan_record) }
          .to change { member.borrowing_history.length }.by(1)
      end
    end

    describe '#current_loans' do
      it 'returns loans without return date' do
        member.add_to_history(loan_record)
        returned_loan = loan_record.dup
        returned_loan[:return_date] = '2023-01-10'
        member.add_to_history(returned_loan)

        current = member.current_loans
        expect(current.length).to eq(1)
        expect(current.first[:return_date]).to be_nil
      end
    end

    describe '#overdue_loans' do
      let(:overdue_loan) do
        {
          book_isbn: '9780306406157',
          checkout_date: '2023-01-01',
          due_date: '2023-01-15',
          return_date: nil
        }
      end

      let(:current_loan) do
        {
          book_isbn: '9780140449136',
          checkout_date: Date.today.to_s,
          due_date: (Date.today + 7).to_s,
          return_date: nil
        }
      end

      it 'returns overdue loans' do
        member.add_to_history(overdue_loan)
        member.add_to_history(current_loan)

        overdue = member.overdue_loans(Date.parse('2023-01-20'))
        expect(overdue.length).to eq(1)
        expect(overdue.first[:book_isbn]).to eq('9780306406157')
      end

      it 'returns empty array when no overdue loans' do
        member.add_to_history(current_loan)
        expect(member.overdue_loans).to be_empty
      end
    end

    describe '#has_overdue_books?' do
      it 'returns true when member has overdue books' do
        overdue_loan = {
          book_isbn: '9780306406157',
          checkout_date: '2023-01-01',
          due_date: '2023-01-15',
          return_date: nil
        }
        member.add_to_history(overdue_loan)
        expect(member.has_overdue_books?(Date.parse('2023-01-20'))).to be true
      end

      it 'returns false when member has no overdue books' do
        expect(member.has_overdue_books?).to be false
      end
    end

    describe '#calculate_late_fees' do
      it 'calculates fees for overdue books' do
        overdue_loan = {
          book_isbn: '9780306406157',
          checkout_date: '2023-01-01',
          due_date: '2023-01-15',
          return_date: nil
        }
        member.add_to_history(overdue_loan)
        
        fees = member.calculate_late_fees(Date.parse('2023-01-20'))
        expect(fees).to eq(50) # 5 days * 10 rubles
      end

      it 'returns 0 when no overdue books' do
        expect(member.calculate_late_fees).to eq(0)
      end

      it 'calculates fees for multiple overdue books' do
        loan1 = {
          book_isbn: '9780306406157',
          checkout_date: '2023-01-01',
          due_date: '2023-01-15',
          return_date: nil
        }
        loan2 = {
          book_isbn: '9780140449136',
          checkout_date: '2023-01-05',
          due_date: '2023-01-19',
          return_date: nil
        }
        member.add_to_history(loan1)
        member.add_to_history(loan2)
        
        fees = member.calculate_late_fees(Date.parse('2023-01-21'))
        expect(fees).to eq(80) # (6 days + 2 days) * 10 rubles
      end
    end

    describe 'statistics methods' do
      before do
        member.add_to_history(loan_record)
        returned_loan = loan_record.dup
        returned_loan[:return_date] = '2023-01-10'
        returned_loan[:book_isbn] = '9780140449136'
        member.add_to_history(returned_loan)
      end

      it '#total_books_borrowed returns total count' do
        expect(member.total_books_borrowed).to eq(2)
      end

      it '#books_currently_borrowed returns current loan count' do
        expect(member.books_currently_borrowed).to eq(1)
      end
    end
  end

  it_behaves_like "a persistable object", Member

  describe 'equality and hashing' do
    let(:member1) { Member.new(**valid_attributes.merge(id: 'same-id')) }
    let(:member2) { Member.new(**valid_attributes.merge(id: 'same-id')) }
    let(:different_member) { Member.new(**valid_attributes.merge(id: 'different-id')) }

    it 'treats members with same ID as equal' do
      expect(member1).to eq(member2)
      expect(member1.eql?(member2)).to be true
    end

    it 'treats members with different ID as not equal' do
      expect(member1).not_to eq(different_member)
    end

    it 'has consistent hash values for equal objects' do
      expect(member1.hash).to eq(member2.hash)
    end
  end

  describe '#to_s' do
    let(:member) { Member.new(**valid_attributes) }

    it 'returns readable string representation' do
      expect(member.to_s).to eq("John Doe (john.doe@example.com)")
    end
  end
end