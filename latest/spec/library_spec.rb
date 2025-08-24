require_relative '../lib/library'
require_relative 'shared_examples'
require 'date'

RSpec.describe Library do
  let(:library) { Library.new('tmp/test_data') }
  
  around(:each) do |example|
    # Ensure temp directory is clean
    if Dir.exist?('tmp/test_data')
      FileUtils.rm_rf('tmp/test_data')
    end
    FileUtils.mkdir_p('tmp/test_data')
    
    example.run
  ensure
    FileUtils.rm_rf('tmp') if Dir.exist?('tmp')
  end

  describe 'initialization' do
    it_behaves_like "a loggable operation", "initialization", "info" do
      subject { Library.new('tmp/test_data') }
    end
  end

  describe '#add_book' do
    let(:book_attributes) do
      {
        isbn: '9780306406157',
        title: 'The Great Gatsby',
        author: 'F. Scott Fitzgerald',
        publication_year: 1925,
        total_copies: 2,
        genre: 'Fiction'
      }
    end

    it_behaves_like "a loggable operation", "add book", "info" do
      subject { library.add_book(**book_attributes) }
    end

    it 'adds new book to library' do
      library.add_book(**book_attributes)
      
      books = library.search_books(query: 'Gatsby')
      expect(books.length).to eq(1)
      expect(books.first.title).to eq('The Great Gatsby')
    end

    it 'adds copies to existing book' do
      library.add_book(**book_attributes)
      library.add_book(**book_attributes.merge(total_copies: 1))
      
      books = library.search_books(query: 'Gatsby')
      expect(books.length).to eq(1)
      expect(books.first.total_copies).to eq(3)
    end

    it 'validates book attributes through Book model' do
      expect {
        library.add_book(**book_attributes.merge(isbn: 'invalid'))
      }.to raise_error(ArgumentError, "Invalid ISBN format")
    end
  end

  describe '#remove_book' do
    let(:book_attributes) do
      {
        isbn: '9780306406157',
        title: 'Test Book',
        author: 'Test Author',
        publication_year: 2020
      }
    end

    before { library.add_book(**book_attributes) }

    it_behaves_like "a loggable operation", "remove book", "info" do
      subject { library.remove_book('9780306406157') }
    end

    it 'removes book from library' do
      removed_book = library.remove_book('9780306406157')
      expect(removed_book.title).to eq('Test Book')
      expect(library.search_books(query: 'Test Book')).to be_empty
    end

    it 'raises error for non-existent book' do
      expect {
        library.remove_book('non-existent')
      }.to raise_error(ArgumentError, "Book not found")
    end

    it 'raises error when book has active loans' do
      member = library.register_member(name: 'Test Member', email: 'test@example.com')
      library.checkout_book(isbn: '9780306406157', member_id: member.id)
      
      expect {
        library.remove_book('9780306406157')
      }.to raise_error(StandardError, "Cannot remove book with active loans")
    end
  end

  describe '#register_member' do
    let(:member_attributes) { { name: 'John Doe', email: 'john@example.com' } }

    it_behaves_like "a loggable operation", "register member", "info" do
      subject { library.register_member(**member_attributes) }
    end

    it 'registers new member' do
      member = library.register_member(**member_attributes)
      expect(member.name).to eq('John Doe')
      expect(member.email).to eq('john@example.com')
      expect(member.id).to be_a(String)
    end

    it 'validates member attributes through Member model' do
      expect {
        library.register_member(name: 'Test', email: 'invalid-email')
      }.to raise_error(ArgumentError, "Invalid email format")
    end
  end

  describe '#checkout_book' do
    let(:book_isbn) { '9780306406157' }
    let(:member) { library.register_member(name: 'Test Member', email: 'test@example.com') }

    before do
      library.add_book(
        isbn: book_isbn,
        title: 'Test Book',
        author: 'Test Author',
        publication_year: 2020,
        total_copies: 2
      )
    end

    it_behaves_like "a loggable operation", "checkout", "info" do
      subject { library.checkout_book(isbn: book_isbn, member_id: member.id) }
    end

    it 'checks out book to member' do
      loan = library.checkout_book(isbn: book_isbn, member_id: member.id)
      
      expect(loan.book_isbn).to eq(book_isbn)
      expect(loan.member_id).to eq(member.id)
      expect(loan.checkout_date).to eq(Date.today)
      expect(loan.due_date).to eq(Date.today + 14)
    end

    it 'updates book availability' do
      library.checkout_book(isbn: book_isbn, member_id: member.id)
      
      books = library.search_books(query: 'Test Book')
      expect(books.first.available_copies).to eq(1)
    end

    it 'updates member borrowing history' do
      library.checkout_book(isbn: book_isbn, member_id: member.id)
      
      history = library.get_member_borrowing_history(member.id)
      expect(history[:borrowing_history].length).to eq(1)
      expect(history[:borrowing_history].first[:book_isbn]).to eq(book_isbn)
    end

    it 'raises error for non-existent book' do
      expect {
        library.checkout_book(isbn: 'non-existent', member_id: member.id)
      }.to raise_error(ArgumentError, "Book not found")
    end

    it 'raises error for non-existent member' do
      expect {
        library.checkout_book(isbn: book_isbn, member_id: 'non-existent')
      }.to raise_error(ArgumentError, "Member not found")
    end

    context 'when no copies available' do
      before do
        library.checkout_book(isbn: book_isbn, member_id: member.id)
        library.checkout_book(isbn: book_isbn, member_id: member.id)
      end

      it 'creates reservation and raises error' do
        expect {
          library.checkout_book(isbn: book_isbn, member_id: member.id)
        }.to raise_error(StandardError, /No copies available. Book reserved/)
      end
    end
  end

  describe '#return_book' do
    let(:book_isbn) { '9780306406157' }
    let(:member) { library.register_member(name: 'Test Member', email: 'test@example.com') }
    let!(:loan) do
      library.add_book(
        isbn: book_isbn,
        title: 'Test Book',
        author: 'Test Author',
        publication_year: 2020
      )
      library.checkout_book(isbn: book_isbn, member_id: member.id)
    end

    it_behaves_like "a loggable operation", "return", "info" do
      subject { library.return_book(isbn: book_isbn, member_id: member.id) }
    end

    it 'returns book and updates availability' do
      returned_loan = library.return_book(isbn: book_isbn, member_id: member.id)
      
      expect(returned_loan.returned?).to be true
      expect(returned_loan.return_date).to eq(Date.today)
      
      books = library.search_books(query: 'Test Book')
      expect(books.first.available_copies).to eq(1)
    end

    it 'updates member borrowing history' do
      library.return_book(isbn: book_isbn, member_id: member.id)
      
      history = library.get_member_borrowing_history(member.id)
      expect(history[:borrowing_history].first[:return_date]).to eq(Date.today.to_s)
    end

    it 'calculates late fees for overdue returns' do
      # Simulate overdue return
      overdue_date = Date.today + 20
      returned_loan = library.return_book(isbn: book_isbn, member_id: member.id, return_date: overdue_date)
      
      expect(returned_loan.late_fee).to eq(60) # 6 days * 10 rubles
    end

    it 'raises error for non-existent book' do
      expect {
        library.return_book(isbn: 'non-existent', member_id: member.id)
      }.to raise_error(ArgumentError, "Book not found")
    end

    it 'raises error for non-existent member' do
      expect {
        library.return_book(isbn: book_isbn, member_id: 'non-existent')
      }.to raise_error(ArgumentError, "Member not found")
    end

    it 'raises error when no active loan found' do
      library.return_book(isbn: book_isbn, member_id: member.id)
      
      expect {
        library.return_book(isbn: book_isbn, member_id: member.id)
      }.to raise_error(ArgumentError, "No active loan found for this book and member")
    end

    context 'with reservations' do
      let(:another_member) { library.register_member(name: 'Another Member', email: 'another@example.com') }

      before do
        library.reserve_book(isbn: book_isbn, member_id: another_member.id)
      end

      it 'fulfills next reservation when book is returned' do
        library.return_book(isbn: book_isbn, member_id: member.id)
        
        # Check that reservation was fulfilled
        stats = library.statistics
        expect(stats[:active_reservations]).to eq(0)
      end
    end
  end

  describe '#reserve_book' do
    let(:book_isbn) { '9780306406157' }
    let(:member) { library.register_member(name: 'Test Member', email: 'test@example.com') }

    before do
      library.add_book(
        isbn: book_isbn,
        title: 'Test Book',
        author: 'Test Author',
        publication_year: 2020
      )
    end

    it_behaves_like "a loggable operation", "reserve", "info" do
      subject { library.reserve_book(isbn: book_isbn, member_id: member.id) }
    end

    it 'creates reservation for book' do
      reservation = library.reserve_book(isbn: book_isbn, member_id: member.id)
      
      expect(reservation.book_isbn).to eq(book_isbn)
      expect(reservation.member_id).to eq(member.id)
      expect(reservation.reservation_date).to eq(Date.today)
      expect(reservation.expiration_date).to eq(Date.today + 3)
    end

    it 'raises error for non-existent book' do
      expect {
        library.reserve_book(isbn: 'non-existent', member_id: member.id)
      }.to raise_error(ArgumentError, "Book not found")
    end

    it 'raises error for non-existent member' do
      expect {
        library.reserve_book(isbn: book_isbn, member_id: 'non-existent')
      }.to raise_error(ArgumentError, "Member not found")
    end

    it 'raises error for duplicate reservation' do
      library.reserve_book(isbn: book_isbn, member_id: member.id)
      
      expect {
        library.reserve_book(isbn: book_isbn, member_id: member.id)
      }.to raise_error(StandardError, "Member already has an active reservation for this book")
    end
  end

  describe '#search_books' do
    before do
      library.add_book(
        isbn: '9780306406157',
        title: 'The Great Gatsby',
        author: 'F. Scott Fitzgerald',
        publication_year: 1925,
        genre: 'Fiction'
      )
      library.add_book(
        isbn: '9780140449136',
        title: 'Crime and Punishment',
        author: 'Fyodor Dostoevsky',
        publication_year: 1866,
        genre: 'Literature'
      )
    end

    it 'searches by title' do
      results = library.search_books(query: 'Gatsby')
      expect(results.length).to eq(1)
      expect(results.first.title).to eq('The Great Gatsby')
    end

    it 'searches by author' do
      results = library.search_books(query: 'Dostoevsky')
      expect(results.length).to eq(1)
      expect(results.first.author).to eq('Fyodor Dostoevsky')
    end

    it 'searches by genre' do
      results = library.search_books(query: 'Fiction')
      expect(results.length).to eq(1)
      expect(results.first.genre).to eq('Fiction')
    end

    it 'is case insensitive' do
      results = library.search_books(query: 'gatsby')
      expect(results.length).to eq(1)
    end

    it 'returns partial matches' do
      results = library.search_books(query: 'Great')
      expect(results.length).to eq(1)
    end

    it 'returns empty array for no matches' do
      results = library.search_books(query: 'nonexistent')
      expect(results).to be_empty
    end
  end

  describe '#members_with_overdue_books' do
    let(:member1) { library.register_member(name: 'Member 1', email: 'member1@example.com') }
    let(:member2) { library.register_member(name: 'Member 2', email: 'member2@example.com') }

    before do
      library.add_book(
        isbn: '9780306406157',
        title: 'Book 1',
        author: 'Author 1',
        publication_year: 2020
      )
      library.add_book(
        isbn: '9780140449136',
        title: 'Book 2',
        author: 'Author 2',
        publication_year: 2020
      )
    end

    it 'returns empty array when no overdue books' do
      library.checkout_book(isbn: '9780306406157', member_id: member1.id)
      
      overdue_members = library.members_with_overdue_books
      expect(overdue_members).to be_empty
    end

    it 'returns members with overdue books' do
      # Create overdue loan by backdating checkout
      overdue_date = Date.today - 20
      loan = Loan.new(
        book_isbn: '9780306406157',
        member_id: member1.id,
        checkout_date: overdue_date
      )
      
      # Simulate the loan in the system
      member1.add_to_history({
        book_isbn: '9780306406157',
        checkout_date: loan.checkout_date.to_s,
        due_date: loan.due_date.to_s,
        return_date: nil
      })
      
      overdue_members = library.members_with_overdue_books(Date.today)
      expect(overdue_members.length).to eq(1)
      expect(overdue_members.first[:member]).to eq(member1)
      expect(overdue_members.first[:total_late_fees]).to eq(60) # 6 days * 10 rubles
    end
  end

  describe '#statistics' do
    let(:member1) { library.register_member(name: 'Member 1', email: 'member1@example.com') }
    let(:member2) { library.register_member(name: 'Member 2', email: 'member2@example.com') }

    before do
      library.add_book(
        isbn: '9780306406157',
        title: 'Popular Book',
        author: 'Author 1',
        publication_year: 2020
      )
      library.add_book(
        isbn: '9780140449136',
        title: 'Less Popular Book',
        author: 'Author 2',
        publication_year: 2020
      )
    end

    it 'returns comprehensive library statistics' do
      # Create some loans to generate statistics
      library.checkout_book(isbn: '9780306406157', member_id: member1.id)
      library.return_book(isbn: '9780306406157', member_id: member1.id)
      
      library.checkout_book(isbn: '9780306406157', member_id: member2.id)
      library.checkout_book(isbn: '9780140449136', member_id: member1.id)
      
      library.reserve_book(isbn: '9780306406157', member_id: member1.id)

      stats = library.statistics
      
      expect(stats[:total_books]).to eq(2)
      expect(stats[:total_members]).to eq(2)
      expect(stats[:active_loans]).to eq(2)
      expect(stats[:active_reservations]).to eq(1)
      expect(stats[:top_5_most_borrowed_books].length).to eq(2)
      expect(stats[:top_5_most_borrowed_books].first[:borrow_count]).to eq(2)
      expect(stats[:most_active_reader]).to eq(member1)
    end

    it 'handles empty library' do
      empty_library = Library.new
      stats = empty_library.statistics
      
      expect(stats[:total_books]).to eq(0)
      expect(stats[:total_members]).to eq(0)
      expect(stats[:active_loans]).to eq(0)
      expect(stats[:active_reservations]).to eq(0)
      expect(stats[:top_5_most_borrowed_books]).to be_empty
      expect(stats[:most_active_reader]).to be_nil
    end
  end

  describe '#get_member_borrowing_history' do
    let(:member) { library.register_member(name: 'Test Member', email: 'test@example.com') }

    before do
      library.add_book(
        isbn: '9780306406157',
        title: 'Test Book',
        author: 'Test Author',
        publication_year: 2020
      )
      library.checkout_book(isbn: '9780306406157', member_id: member.id)
    end

    it 'returns member borrowing history with book details' do
      history = library.get_member_borrowing_history(member.id)
      
      expect(history[:member]).to eq(member)
      expect(history[:borrowing_history].length).to eq(1)
      expect(history[:borrowing_history].first[:book_title]).to eq('Test Book')
      expect(history[:borrowing_history].first[:book_author]).to eq('Test Author')
      expect(history[:current_loans_count]).to eq(1)
      expect(history[:total_books_borrowed]).to eq(1)
    end

    it 'raises error for non-existent member' do
      expect {
        library.get_member_borrowing_history('non-existent')
      }.to raise_error(ArgumentError, "Member not found")
    end
  end

  describe '#cleanup_expired_reservations' do
    let(:member) { library.register_member(name: 'Test Member', email: 'test@example.com') }

    before do
      library.add_book(
        isbn: '9780306406157',
        title: 'Test Book',
        author: 'Test Author',
        publication_year: 2020
      )
    end

    it 'removes expired reservations' do
      # Create expired reservation
      reservation = Reservation.new(
        book_isbn: '9780306406157',
        member_id: member.id,
        reservation_date: Date.today - 10
      )
      
      library.instance_variable_get(:@data_store).save_reservation(reservation)
      
      count = library.cleanup_expired_reservations
      expect(count).to eq(1)
      
      stats = library.statistics
      expect(stats[:active_reservations]).to eq(0)
    end

    it 'does not remove active reservations' do
      library.reserve_book(isbn: '9780306406157', member_id: member.id)
      
      count = library.cleanup_expired_reservations
      expect(count).to eq(0)
      
      stats = library.statistics
      expect(stats[:active_reservations]).to eq(1)
    end

    it 'logs expired reservation removals' do
      reservation = Reservation.new(
        book_isbn: '9780306406157',
        member_id: member.id,
        reservation_date: Date.today - 10
      )
      
      library.instance_variable_get(:@data_store).save_reservation(reservation)
      
      expect(LibraryLogger).to receive(:info).with("Expired reservation removed", anything)
      library.cleanup_expired_reservations
    end
  end
end