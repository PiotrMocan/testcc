require 'spec_helper'

RSpec.describe LibrarySystem do
  let(:mock_persistence) { instance_double(PersistenceService) }
  let(:mock_logger) { instance_double(LoggingService) }

  let(:sample_book) do
    Book.new(
      isbn: '9780132350884',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      publication_year: 2008,
      total_copies: 3,
      genre: 'Programming'
    )
  end

  let(:sample_member) do
    Member.new(
      id: 'MEM001',
      name: 'John Doe',
      email: 'john@example.com'
    )
  end

  before do
    allow(PersistenceService).to receive(:new).and_return(mock_persistence)
    allow(LoggingService).to receive(:new).and_return(mock_logger)
    
    allow(mock_persistence).to receive(:load_books).and_return([])
    allow(mock_persistence).to receive(:load_members).and_return([])
    allow(mock_persistence).to receive(:load_loans).and_return([])
    allow(mock_persistence).to receive(:load_reservations).and_return([])
    
    allow(mock_persistence).to receive(:save_books)
    allow(mock_persistence).to receive(:save_members)
    allow(mock_persistence).to receive(:save_loans)
    allow(mock_persistence).to receive(:save_reservations)
    
    allow(mock_logger).to receive(:log_operation)
    allow(mock_logger).to receive(:log_error)
  end

  subject { described_class.new }

  describe '#initialize' do
    it 'loads data from persistence service' do
      expect(mock_persistence).to receive(:load_books)
      expect(mock_persistence).to receive(:load_members)
      expect(mock_persistence).to receive(:load_loans)
      expect(mock_persistence).to receive(:load_reservations)
      expect(mock_logger).to receive(:log_operation).with('Data loaded from storage')
      
      described_class.new
    end
  end

  describe '#add_book' do
    let(:book_attributes) do
      {
        isbn: '9780132350884',
        title: 'Clean Code',
        author: 'Robert C. Martin',
        publication_year: 2008,
        total_copies: 3,
        genre: 'Programming'
      }
    end

    context 'when adding a new book' do
      it 'adds book and logs operation' do
        expect(mock_logger).to receive(:log_operation).with('Book added', hash_including(isbn: '9780132350884'))
        expect(mock_persistence).to receive(:save_books)
        
        result = subject.add_book(**book_attributes)
        expect(result).to be true
      end
    end

    context 'when adding copies of existing book' do
      before do
        allow(mock_persistence).to receive(:load_books).and_return([sample_book])
        subject.instance_variable_set(:@books, [sample_book])
      end

      it 'adds copies to existing book' do
        original_copies = sample_book.total_copies
        
        expect(mock_logger).to receive(:log_operation).with('Book copies added', hash_including(isbn: '9780132350884'))
        expect(mock_persistence).to receive(:save_books)
        
        subject.add_book(**book_attributes)
        expect(sample_book.total_copies).to eq(original_copies + 3)
        expect(sample_book.available_copies).to eq(original_copies + 3)
      end
    end

    context 'with invalid book data' do
      it 'logs error and raises exception' do
        invalid_attributes = book_attributes.merge(isbn: 'invalid')
        
        expect(mock_logger).to receive(:log_error).with('Add book', kind_of(ArgumentError))
        expect { subject.add_book(**invalid_attributes) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#remove_book' do
    before do
      subject.instance_variable_set(:@books, [sample_book])
      subject.instance_variable_set(:@loans, [])
      subject.instance_variable_set(:@reservations, [])
    end

    context 'when book exists and no active loans' do
      it 'removes book and logs operation' do
        expect(mock_logger).to receive(:log_operation).with('Book removed', {isbn: sample_book.isbn})
        expect(mock_persistence).to receive(:save_books)
        
        result = subject.remove_book(sample_book.isbn)
        expect(result).to be true
      end
    end

    context 'when book has active loans' do
      let(:active_loan) do
        Loan.new(id: 'LOAN_001', book_isbn: sample_book.isbn, member_id: 'MEM001')
      end

      before do
        subject.instance_variable_set(:@loans, [active_loan])
      end

      it 'raises error and logs it' do
        expect(mock_logger).to receive(:log_error).with('Remove book', kind_of(RuntimeError))
        expect { subject.remove_book(sample_book.isbn) }.to raise_error('Cannot remove book with active loans')
      end
    end

    context 'when book does not exist' do
      it 'raises error and logs it' do
        expect(mock_logger).to receive(:log_error).with('Remove book', kind_of(RuntimeError))
        expect { subject.remove_book('nonexistent') }.to raise_error('Book with ISBN nonexistent not found')
      end
    end
  end

  describe '#register_member' do
    let(:member_attributes) do
      {
        id: 'MEM001',
        name: 'John Doe',
        email: 'john@example.com'
      }
    end

    context 'with valid member data' do
      it 'registers member and logs operation' do
        expect(mock_logger).to receive(:log_operation).with('Member registered', member_attributes)
        expect(mock_persistence).to receive(:save_members)
        
        result = subject.register_member(**member_attributes)
        expect(result).to be true
      end
    end

    context 'when member ID already exists' do
      before do
        subject.instance_variable_set(:@members, [sample_member])
      end

      it 'raises error and logs it' do
        expect(mock_logger).to receive(:log_error).with('Register member', kind_of(RuntimeError))
        expect { subject.register_member(**member_attributes) }.to raise_error('Member with ID MEM001 already exists')
      end
    end

    context 'when email already exists' do
      let(:existing_member) do
        Member.new(id: 'MEM002', name: 'Jane Doe', email: 'john@example.com')
      end

      before do
        subject.instance_variable_set(:@members, [existing_member])
      end

      it 'raises error and logs it' do
        expect(mock_logger).to receive(:log_error).with('Register member', kind_of(RuntimeError))
        expect { subject.register_member(**member_attributes) }.to raise_error('Member with email john@example.com already exists')
      end
    end
  end

  describe '#checkout_book' do
    before do
      subject.instance_variable_set(:@books, [sample_book])
      subject.instance_variable_set(:@members, [sample_member])
      subject.instance_variable_set(:@loans, [])
      subject.instance_variable_set(:@reservations, [])
    end

    context 'when book is available' do
      it 'creates loan and logs operation' do
        expect(mock_logger).to receive(:log_operation).with('Book checked out', hash_including(member_id: 'MEM001', isbn: '9780132350884'))
        expect(mock_persistence).to receive(:save_books)
        expect(mock_persistence).to receive(:save_members)
        expect(mock_persistence).to receive(:save_loans)
        
        result = subject.checkout_book(member_id: 'MEM001', isbn: '9780132350884')
        expect(result).to be_a(Loan)
        expect(sample_book.available_copies).to eq(2)
      end

      it 'adds loan to member history' do
        subject.checkout_book(member_id: 'MEM001', isbn: '9780132350884')
        expect(sample_member.borrowing_history.size).to eq(1)
        expect(sample_member.borrowing_history.first[:book_isbn]).to eq('9780132350884')
      end
    end

    context 'when book is not available' do
      before do
        sample_book.available_copies = 0
        allow(subject).to receive(:reserve_book).and_return(double('reservation'))
      end

      it 'creates reservation instead' do
        expect(subject).to receive(:reserve_book).with(member_id: 'MEM001', isbn: '9780132350884')
        
        result = subject.checkout_book(member_id: 'MEM001', isbn: '9780132350884')
        expect(result).not_to be_a(Loan)
      end
    end

    context 'when member does not exist' do
      it 'raises error and logs it' do
        expect(mock_logger).to receive(:log_error).with('Checkout book', kind_of(RuntimeError))
        expect { subject.checkout_book(member_id: 'NONEXISTENT', isbn: '9780132350884') }.to raise_error('Member with ID NONEXISTENT not found')
      end
    end
  end

  describe '#return_book' do
    let(:fixed_time) { Time.new(2023, 6, 1, 12, 0, 0) }
    let(:loan) do
      Loan.new(
        id: 'LOAN_001',
        book_isbn: '9780132350884',
        member_id: 'MEM001',
        checkout_date: fixed_time
      )
    end

    before do
      sample_book.available_copies = 2
      sample_member.add_to_history({
        book_isbn: '9780132350884',
        checkout_date: loan.checkout_date,
        due_date: loan.due_date,
        return_date: nil
      })
      
      subject.instance_variable_set(:@books, [sample_book])
      subject.instance_variable_set(:@members, [sample_member])
      subject.instance_variable_set(:@loans, [loan])
      subject.instance_variable_set(:@reservations, [])
      
      allow(subject).to receive(:process_next_reservation)
    end

    context 'when returning on time' do
      let(:return_date) { loan.due_date - (1 * 24 * 60 * 60) }

      it 'processes return with no late fee' do
        expect(mock_logger).to receive(:log_operation).with('Book returned', hash_including(late_fee: 0.0))
        expect(mock_persistence).to receive(:save_books)
        expect(mock_persistence).to receive(:save_members)
        expect(mock_persistence).to receive(:save_loans)
        
        result = subject.return_book(member_id: 'MEM001', isbn: '9780132350884', return_date: return_date)
        
        expect(result[:late_fee]).to eq(0.0)
        expect(result[:days_overdue]).to eq(0)
        expect(sample_book.available_copies).to eq(3)
      end
    end

    context 'when returning late' do
      let(:return_date) { loan.due_date + (3 * 24 * 60 * 60) }

      it 'processes return with late fee' do
        expect(mock_logger).to receive(:log_operation).with('Book returned', hash_including(late_fee: 30.0, days_overdue: 3))
        
        result = subject.return_book(member_id: 'MEM001', isbn: '9780132350884', return_date: return_date)
        
        expect(result[:late_fee]).to eq(30.0)
        expect(result[:days_overdue]).to eq(3)
      end
    end

    it 'processes next reservation' do
      expect(subject).to receive(:process_next_reservation).with('9780132350884')
      subject.return_book(member_id: 'MEM001', isbn: '9780132350884')
    end

    context 'when no active loan found' do
      before do
        loan.return_book
      end

      it 'raises error and logs it' do
        expect(mock_logger).to receive(:log_error).with('Return book', kind_of(RuntimeError))
        expect { subject.return_book(member_id: 'MEM001', isbn: '9780132350884') }.to raise_error('No active loan found for this book and member')
      end
    end
  end

  describe '#reserve_book' do
    before do
      sample_book.available_copies = 0
      subject.instance_variable_set(:@books, [sample_book])
      subject.instance_variable_set(:@members, [sample_member])
      subject.instance_variable_set(:@reservations, [])
    end

    context 'when book is not available' do
      it 'creates reservation and logs operation' do
        expect(mock_logger).to receive(:log_operation).with('Book reserved', hash_including(member_id: 'MEM001', isbn: '9780132350884'))
        expect(mock_persistence).to receive(:save_reservations)
        
        result = subject.reserve_book(member_id: 'MEM001', isbn: '9780132350884')
        expect(result).to be_a(Reservation)
      end
    end

    context 'when book is available' do
      before do
        sample_book.available_copies = 1
      end

      it 'returns false' do
        result = subject.reserve_book(member_id: 'MEM001', isbn: '9780132350884')
        expect(result).to be false
      end
    end

    context 'when member already has active reservation' do
      let(:existing_reservation) do
        Reservation.new(id: 'RES_001', book_isbn: '9780132350884', member_id: 'MEM001')
      end

      before do
        subject.instance_variable_set(:@reservations, [existing_reservation])
      end

      it 'raises error and logs it' do
        expect(mock_logger).to receive(:log_error).with('Reserve book', kind_of(RuntimeError))
        expect { subject.reserve_book(member_id: 'MEM001', isbn: '9780132350884') }.to raise_error('Member already has an active reservation for this book')
      end
    end
  end

  describe '#search_books' do
    let(:book1) do
      Book.new(isbn: '1111111111', title: 'Ruby Programming', author: 'John Smith', publication_year: 2020, total_copies: 2, genre: 'Programming')
    end
    
    let(:book2) do
      Book.new(isbn: '2222222222', title: 'JavaScript Guide', author: 'Jane Doe', publication_year: 2019, total_copies: 1, genre: 'Programming')
    end
    
    let(:book3) do
      Book.new(isbn: '3333333333', title: 'Cooking Basics', author: 'Chef Ruby', publication_year: 2021, total_copies: 3, genre: 'Cooking')
    end

    before do
      subject.instance_variable_set(:@books, [book1, book2, book3])
    end

    context 'searching by title' do
      it 'finds books matching title' do
        results = subject.search_books(query: 'ruby', field: :title)
        expect(results.size).to eq(1)
        expect(results.first.title).to eq('Ruby Programming')
      end
    end

    context 'searching by author' do
      it 'finds books matching author' do
        results = subject.search_books(query: 'jane', field: :author)
        expect(results.size).to eq(1)
        expect(results.first.author).to eq('Jane Doe')
      end
    end

    context 'searching by genre' do
      it 'finds books matching genre' do
        results = subject.search_books(query: 'programming', field: :genre)
        expect(results.size).to eq(2)
      end
    end

    context 'searching by ISBN' do
      it 'finds books matching ISBN' do
        results = subject.search_books(query: '1111', field: :isbn)
        expect(results.size).to eq(1)
        expect(results.first.isbn).to eq('1111111111')
      end
    end

    context 'searching all fields' do
      it 'finds books matching any field' do
        results = subject.search_books(query: 'ruby', field: :all)
        expect(results.size).to eq(2) # 'Ruby Programming' and 'Chef Ruby'
      end
    end

    context 'case insensitive search' do
      it 'performs case insensitive search' do
        results = subject.search_books(query: 'RUBY', field: :title)
        expect(results.size).to eq(1)
      end
    end
  end

  describe '#get_overdue_members' do
    let(:current_time) { Time.new(2023, 6, 20, 12, 0, 0) }
    let(:overdue_loan) do
      Loan.new(
        id: 'LOAN_001',
        book_isbn: '9780132350884',
        member_id: 'MEM001',
        checkout_date: current_time - (25 * 24 * 60 * 60)
      )
    end

    before do
      sample_member.add_to_history({
        book_isbn: '9780132350884',
        checkout_date: overdue_loan.checkout_date,
        due_date: overdue_loan.due_date,
        return_date: nil
      })
      
      subject.instance_variable_set(:@members, [sample_member])
      subject.instance_variable_set(:@loans, [overdue_loan])
    end

    it 'returns overdue member information' do
      overdue_info = subject.get_overdue_members(current_time)
      
      expect(overdue_info.size).to eq(1)
      expect(overdue_info.first[:member]).to eq(sample_member)
      expect(overdue_info.first[:total_late_fee]).to eq(110.0) # 11 days * 10 rubles
      expect(overdue_info.first[:overdue_books].size).to eq(1)
    end

    it 'returns empty array when no overdue members' do
      early_time = current_time - (30 * 24 * 60 * 60)
      overdue_info = subject.get_overdue_members(early_time)
      
      expect(overdue_info).to be_empty
    end
  end

  describe '#get_statistics' do
    let(:book1) { Book.new(isbn: '1111111111', title: 'Book 1', author: 'Author 1', publication_year: 2020, total_copies: 2, genre: 'Fiction') }
    let(:book2) { Book.new(isbn: '2222222222', title: 'Book 2', author: 'Author 2', publication_year: 2021, total_copies: 1, genre: 'Non-fiction') }
    
    let(:member1) { Member.new(id: 'MEM001', name: 'Member 1', email: 'member1@test.com') }
    let(:member2) { Member.new(id: 'MEM002', name: 'Member 2', email: 'member2@test.com') }

    let(:loan1) { Loan.new(id: 'LOAN_001', book_isbn: '1111111111', member_id: 'MEM001') }
    let(:loan2) { Loan.new(id: 'LOAN_002', book_isbn: '1111111111', member_id: 'MEM002') }
    let(:loan3) { Loan.new(id: 'LOAN_003', book_isbn: '2222222222', member_id: 'MEM001') }

    let(:reservation1) { Reservation.new(id: 'RES_001', book_isbn: '1111111111', member_id: 'MEM001') }

    before do
      member1.borrowing_history = [{}, {}, {}] # 3 books borrowed
      member2.borrowing_history = [{}] # 1 book borrowed
      
      subject.instance_variable_set(:@books, [book1, book2])
      subject.instance_variable_set(:@members, [member1, member2])
      subject.instance_variable_set(:@loans, [loan1, loan2, loan3])
      subject.instance_variable_set(:@reservations, [reservation1])
    end

    it 'returns comprehensive statistics' do
      stats = subject.get_statistics
      
      expect(stats[:total_books]).to eq(2)
      expect(stats[:total_members]).to eq(2)
      expect(stats[:active_loans]).to eq(3)
      expect(stats[:active_reservations]).to eq(1)
      
      expect(stats[:top_borrowed_books].first[:book]).to eq(book1)
      expect(stats[:top_borrowed_books].first[:borrow_count]).to eq(2)
      
      expect(stats[:most_active_member][:member]).to eq(member1)
      expect(stats[:most_active_member][:borrow_count]).to eq(3)
    end
  end

  describe '#cleanup_expired_reservations' do
    let(:current_time) { Time.new(2023, 6, 20, 12, 0, 0) }
    
    let(:active_reservation) do
      Reservation.new(
        id: 'RES_001',
        book_isbn: '1111111111',
        member_id: 'MEM001',
        reservation_date: current_time - (1 * 24 * 60 * 60)
      )
    end
    
    let(:expired_reservation) do
      Reservation.new(
        id: 'RES_002',
        book_isbn: '2222222222',
        member_id: 'MEM002',
        reservation_date: current_time - (5 * 24 * 60 * 60)
      )
    end

    before do
      subject.instance_variable_set(:@reservations, [active_reservation, expired_reservation])
    end

    it 'removes expired reservations and logs operation' do
      expect(mock_logger).to receive(:log_operation).with('Expired reservations cleaned up', {count: 1})
      expect(mock_persistence).to receive(:save_reservations)
      
      count = subject.cleanup_expired_reservations(current_time)
      
      expect(count).to eq(1)
      reservations = subject.instance_variable_get(:@reservations)
      expect(reservations.size).to eq(1)
      expect(reservations.first.id).to eq('RES_001')
    end

    it 'returns 0 when no expired reservations' do
      early_time = current_time - (10 * 24 * 60 * 60)
      count = subject.cleanup_expired_reservations(early_time)
      expect(count).to eq(0)
    end
  end

  describe '#get_member_history' do
    before do
      sample_member.borrowing_history = [{book_isbn: '123'}, {book_isbn: '456'}]
      subject.instance_variable_set(:@members, [sample_member])
    end

    it 'returns member borrowing history' do
      history = subject.get_member_history('MEM001')
      expect(history.size).to eq(2)
      expect(history.first[:book_isbn]).to eq('123')
    end

    it 'raises error when member not found' do
      expect { subject.get_member_history('NONEXISTENT') }.to raise_error('Member with ID NONEXISTENT not found')
    end
  end
end