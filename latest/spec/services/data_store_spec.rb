require_relative '../../lib/services/data_store'
require_relative '../shared_examples'
require 'fileutils'
require 'json'

RSpec.describe DataStore do
  let(:data_store) { DataStore.new('tmp/test_data') }
  let(:book) do
    Book.new(
      isbn: '9780306406157',
      title: 'Test Book',
      author: 'Test Author',
      publication_year: 2020
    )
  end
  let(:member) do
    Member.new(name: 'Test Member', email: 'test@example.com')
  end
  let(:loan) do
    Loan.new(book_isbn: book.isbn, member_id: member.id)
  end
  let(:reservation) do
    Reservation.new(book_isbn: book.isbn, member_id: member.id)
  end

  around(:each) do |example|
    with_temp_files do
      # Ensure temp directory is completely clean
      if Dir.exist?('tmp/test_data')
        FileUtils.rm_rf('tmp/test_data')
        FileUtils.mkdir_p('tmp/test_data')
      end
      example.run
    end
  end

  describe 'initialization' do
    it 'creates data directory if it does not exist' do
      expect(Dir.exist?('tmp/test_data')).to be true
    end

    it 'loads existing data on initialization' do
      book_data = { book.isbn => book.to_hash }
      File.write(File.join('tmp/test_data', 'books.json'), JSON.pretty_generate(book_data))
      
      new_store = DataStore.new
      loaded_book = new_store.find_book(book.isbn)
      expect(loaded_book.title).to eq(book.title)
    end

    it 'handles missing data files gracefully' do
      expect { DataStore.new }.not_to raise_error
    end

    it 'handles corrupted JSON files gracefully' do
      File.write(File.join('tmp/test_data', 'books.json'), 'invalid json')
      expect(LibraryLogger).to receive(:error).with("Failed to parse books file", error: anything)
      expect { DataStore.new }.not_to raise_error
    end
  end

  describe 'book operations' do
    it_behaves_like "a loggable operation", "save" do
      subject { data_store.save_book(book) }
    end

    describe '#save_book' do
      it 'saves book to memory and file' do
        data_store.save_book(book)
        expect(data_store.find_book(book.isbn)).to eq(book)
      end

      it 'persists book to file' do
        data_store.save_book(book)
        
        file_content = JSON.parse(File.read(File.join('tmp/test_data', 'books.json')))
        expect(file_content[book.isbn]['title']).to eq(book.title)
      end
    end

    describe '#find_book' do
      before { data_store.save_book(book) }

      it 'returns book by ISBN' do
        found_book = data_store.find_book(book.isbn)
        expect(found_book).to eq(book)
      end

      it 'returns nil for non-existent ISBN' do
        expect(data_store.find_book('non-existent')).to be_nil
      end
    end

    describe '#all_books' do
      it 'returns empty array when no books' do
        expect(data_store.all_books).to be_empty
      end

      it 'returns all books' do
        book2 = Book.new(
          isbn: '9780140449136',
          title: 'Another Book',
          author: 'Another Author',
          publication_year: 2021
        )
        data_store.save_book(book)
        data_store.save_book(book2)
        
        books = data_store.all_books
        expect(books.length).to eq(2)
        expect(books).to include(book, book2)
      end
    end

    describe '#remove_book' do
      before { data_store.save_book(book) }

      it 'removes book from memory and returns it' do
        removed_book = data_store.remove_book(book.isbn)
        expect(removed_book).to eq(book)
        expect(data_store.find_book(book.isbn)).to be_nil
      end

      it 'persists removal to file' do
        data_store.remove_book(book.isbn)
        
        file_content = JSON.parse(File.read(File.join('tmp/test_data', 'books.json')))
        expect(file_content[book.isbn]).to be_nil
      end

      it 'returns nil for non-existent book' do
        expect(data_store.remove_book('non-existent')).to be_nil
      end
    end
  end

  describe 'member operations' do
    it_behaves_like "a loggable operation", "save" do
      subject { data_store.save_member(member) }
    end

    describe '#save_member' do
      it 'saves member to memory and file' do
        data_store.save_member(member)
        expect(data_store.find_member(member.id)).to eq(member)
      end

      it 'persists member to file' do
        data_store.save_member(member)
        
        file_content = JSON.parse(File.read(File.join('tmp/test_data', 'members.json')))
        expect(file_content[member.id]['name']).to eq(member.name)
      end
    end

    describe '#find_member' do
      before { data_store.save_member(member) }

      it 'returns member by ID' do
        found_member = data_store.find_member(member.id)
        expect(found_member).to eq(member)
      end

      it 'returns nil for non-existent ID' do
        expect(data_store.find_member('non-existent')).to be_nil
      end
    end

    describe '#all_members' do
      it 'returns empty array when no members' do
        expect(data_store.all_members).to be_empty
      end

      it 'returns all members' do
        member2 = Member.new(name: 'Another Member', email: 'another@example.com')
        data_store.save_member(member)
        data_store.save_member(member2)
        
        members = data_store.all_members
        expect(members.length).to eq(2)
        expect(members).to include(member, member2)
      end
    end
  end

  describe 'loan operations' do
    it_behaves_like "a loggable operation", "save" do
      subject { data_store.save_loan(loan) }
    end

    describe '#save_loan' do
      it 'saves loan to memory and file' do
        data_store.save_loan(loan)
        expect(data_store.find_loan(loan.id)).to eq(loan)
      end
    end

    describe '#active_loans' do
      it 'returns only active loans' do
        returned_loan = Loan.new(book_isbn: '9780140449136', member_id: 'member2')
        returned_loan.return_book
        
        data_store.save_loan(loan)
        data_store.save_loan(returned_loan)
        
        active = data_store.active_loans
        expect(active.length).to eq(1)
        expect(active.first).to eq(loan)
      end
    end

    describe '#loans_for_member' do
      it 'returns loans for specific member' do
        other_loan = Loan.new(book_isbn: '9780140449136', member_id: 'other-member')
        
        data_store.save_loan(loan)
        data_store.save_loan(other_loan)
        
        member_loans = data_store.loans_for_member(member.id)
        expect(member_loans.length).to eq(1)
        expect(member_loans.first).to eq(loan)
      end
    end

    describe '#loans_for_book' do
      it 'returns loans for specific book' do
        other_loan = Loan.new(book_isbn: '9780140449136', member_id: member.id)
        
        data_store.save_loan(loan)
        data_store.save_loan(other_loan)
        
        book_loans = data_store.loans_for_book(book.isbn)
        expect(book_loans.length).to eq(1)
        expect(book_loans.first).to eq(loan)
      end
    end
  end

  describe 'reservation operations' do
    it_behaves_like "a loggable operation", "save" do
      subject { data_store.save_reservation(reservation) }
    end

    describe '#save_reservation' do
      it 'saves reservation to memory and file' do
        data_store.save_reservation(reservation)
        expect(data_store.find_reservation(reservation.id)).to eq(reservation)
      end
    end

    describe '#active_reservations' do
      it 'returns only active reservations' do
        expired_reservation = Reservation.new(
          book_isbn: '9780140449136',
          member_id: 'member2',
          reservation_date: Date.today - 10
        )
        
        data_store.save_reservation(reservation)
        data_store.save_reservation(expired_reservation)
        
        active = data_store.active_reservations
        expect(active.length).to eq(1)
        expect(active.first).to eq(reservation)
      end
    end

    describe '#reservations_for_book' do
      it 'returns active reservations for specific book' do
        expired_reservation = Reservation.new(
          book_isbn: book.isbn,
          member_id: 'member2',
          reservation_date: Date.today - 10
        )
        other_reservation = Reservation.new(book_isbn: '9780140449136', member_id: member.id)
        
        data_store.save_reservation(reservation)
        data_store.save_reservation(expired_reservation)
        data_store.save_reservation(other_reservation)
        
        book_reservations = data_store.reservations_for_book(book.isbn)
        expect(book_reservations.length).to eq(1)
        expect(book_reservations.first).to eq(reservation)
      end
    end

    describe '#reservations_for_member' do
      it 'returns all reservations for specific member' do
        other_reservation = Reservation.new(book_isbn: '9780140449136', member_id: 'other-member')
        
        data_store.save_reservation(reservation)
        data_store.save_reservation(other_reservation)
        
        member_reservations = data_store.reservations_for_member(member.id)
        expect(member_reservations.length).to eq(1)
        expect(member_reservations.first).to eq(reservation)
      end
    end

    describe '#remove_reservation' do
      before { data_store.save_reservation(reservation) }

      it 'removes reservation from memory and returns it' do
        removed = data_store.remove_reservation(reservation.id)
        expect(removed).to eq(reservation)
        expect(data_store.find_reservation(reservation.id)).to be_nil
      end

      it 'returns nil for non-existent reservation' do
        expect(data_store.remove_reservation('non-existent')).to be_nil
      end
    end
  end

  describe 'file operation failures' do
    it 'raises error when file write fails' do
      allow(File).to receive(:write).and_raise(StandardError.new("Write failed"))
      expect(LibraryLogger).to receive(:error)
      
      expect { data_store.save_book(book) }.to raise_error(StandardError)
    end
  end
end