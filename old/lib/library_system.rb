require_relative 'models/book'
require_relative 'models/member'
require_relative 'models/loan'
require_relative 'models/reservation'
require_relative 'services/persistence_service'
require_relative 'services/logging_service'

class LibrarySystem
  def initialize
    @persistence = PersistenceService.new
    @logger = LoggingService.new
    load_data
  end

  def add_book(isbn:, title:, author:, publication_year:, total_copies:, genre:)
    begin
      existing_book = find_book_by_isbn(isbn)
      
      if existing_book
        existing_book.total_copies += total_copies
        existing_book.available_copies += total_copies
        @logger.log_operation("Book copies added", {isbn: isbn, copies_added: total_copies})
      else
        book = Book.new(
          isbn: isbn,
          title: title,
          author: author,
          publication_year: publication_year,
          total_copies: total_copies,
          genre: genre
        )
        @books << book
        @logger.log_operation("Book added", {isbn: isbn, title: title})
      end
      
      save_data
      true
    rescue => e
      @logger.log_error("Add book", e)
      raise e
    end
  end

  def remove_book(isbn)
    begin
      book = find_book_by_isbn(isbn)
      raise "Book with ISBN #{isbn} not found" unless book
      
      active_loans = @loans.select { |loan| loan.book_isbn == isbn && loan.active? }
      raise "Cannot remove book with active loans" unless active_loans.empty?
      
      @books.reject! { |b| b.isbn == isbn }
      @reservations.reject! { |r| r.book_isbn == isbn }
      
      @logger.log_operation("Book removed", {isbn: isbn})
      save_data
      true
    rescue => e
      @logger.log_error("Remove book", e)
      raise e
    end
  end

  def register_member(id:, name:, email:)
    begin
      existing_member = find_member_by_id(id)
      raise "Member with ID #{id} already exists" if existing_member
      
      existing_email = @members.find { |m| m.email == email.downcase }
      raise "Member with email #{email} already exists" if existing_email
      
      member = Member.new(id: id, name: name, email: email)
      @members << member
      
      @logger.log_operation("Member registered", {id: id, name: name, email: email})
      save_data
      true
    rescue => e
      @logger.log_error("Register member", e)
      raise e
    end
  end

  def checkout_book(member_id:, isbn:)
    begin
      member = find_member_by_id(member_id)
      raise "Member with ID #{member_id} not found" unless member
      
      book = find_book_by_isbn(isbn)
      raise "Book with ISBN #{isbn} not found" unless book
      
      if book.available?
        book.checkout
        loan_id = generate_loan_id
        loan = Loan.new(id: loan_id, book_isbn: isbn, member_id: member_id)
        @loans << loan
        
        member.add_to_history({
          book_isbn: isbn,
          checkout_date: loan.checkout_date,
          due_date: loan.due_date,
          return_date: nil
        })
        
        @logger.log_operation("Book checked out", {member_id: member_id, isbn: isbn, loan_id: loan_id})
        save_data
        loan
      else
        reservation = reserve_book(member_id: member_id, isbn: isbn)
        raise "Book not available and reservation failed" unless reservation
        reservation
      end
    rescue => e
      @logger.log_error("Checkout book", e)
      raise e
    end
  end

  def return_book(member_id:, isbn:, return_date: Time.now)
    begin
      member = find_member_by_id(member_id)
      raise "Member with ID #{member_id} not found" unless member
      
      book = find_book_by_isbn(isbn)
      raise "Book with ISBN #{isbn} not found" unless book
      
      loan = @loans.find { |l| l.member_id == member_id && l.book_isbn == isbn && l.active? }
      raise "No active loan found for this book and member" unless loan
      
      loan.return_book(return_date)
      book.return_book
      
      member.borrowing_history.find { |h| h[:book_isbn] == isbn && h[:return_date].nil? }[:return_date] = return_date
      
      late_fee = loan.late_fee(return_date)
      
      process_next_reservation(isbn)
      
      @logger.log_operation("Book returned", {
        member_id: member_id, 
        isbn: isbn, 
        late_fee: late_fee,
        days_overdue: loan.days_overdue(return_date)
      })
      
      save_data
      { late_fee: late_fee, days_overdue: loan.days_overdue(return_date) }
    rescue => e
      @logger.log_error("Return book", e)
      raise e
    end
  end

  def reserve_book(member_id:, isbn:)
    begin
      member = find_member_by_id(member_id)
      raise "Member with ID #{member_id} not found" unless member
      
      book = find_book_by_isbn(isbn)
      raise "Book with ISBN #{isbn} not found" unless book
      
      return false if book.available?
      
      existing_reservation = @reservations.find do |r| 
        r.member_id == member_id && r.book_isbn == isbn && r.active?
      end
      raise "Member already has an active reservation for this book" if existing_reservation
      
      reservation_id = generate_reservation_id
      reservation = Reservation.new(
        id: reservation_id,
        book_isbn: isbn,
        member_id: member_id
      )
      @reservations << reservation
      
      @logger.log_operation("Book reserved", {member_id: member_id, isbn: isbn, reservation_id: reservation_id})
      save_data
      reservation
    rescue => e
      @logger.log_error("Reserve book", e)
      raise e
    end
  end

  def search_books(query:, field: :all)
    query = query.downcase
    @books.select do |book|
      case field
      when :title
        book.title.downcase.include?(query)
      when :author
        book.author.downcase.include?(query)
      when :genre
        book.genre.downcase.include?(query)
      when :isbn
        book.isbn.include?(query)
      else
        book.title.downcase.include?(query) ||
        book.author.downcase.include?(query) ||
        book.genre.downcase.include?(query) ||
        book.isbn.include?(query)
      end
    end
  end

  def get_overdue_members(current_date = Time.now)
    overdue_info = []
    @members.each do |member|
      overdue_loans = member.overdue_loans(current_date)
      unless overdue_loans.empty?
        total_fee = overdue_loans.sum do |loan_history|
          loan = @loans.find { |l| l.book_isbn == loan_history[:book_isbn] && l.member_id == member.id && l.active? }
          loan ? loan.late_fee(current_date) : 0
        end
        
        overdue_info << {
          member: member,
          overdue_books: overdue_loans,
          total_late_fee: total_fee
        }
      end
    end
    overdue_info
  end

  def get_statistics
    active_loans = @loans.select(&:active?)
    
    book_borrow_counts = {}
    @loans.each do |loan|
      book_borrow_counts[loan.book_isbn] = (book_borrow_counts[loan.book_isbn] || 0) + 1
    end
    
    top_books = book_borrow_counts.sort_by { |_, count| -count }.first(5).map do |isbn, count|
      book = find_book_by_isbn(isbn)
      { book: book, borrow_count: count }
    end
    
    member_borrow_counts = {}
    @members.each do |member|
      member_borrow_counts[member.id] = member.total_borrowed_books
    end
    
    most_active_member = member_borrow_counts.max_by { |_, count| count }
    most_active_member_obj = most_active_member ? find_member_by_id(most_active_member[0]) : nil
    
    {
      total_books: @books.size,
      total_members: @members.size,
      active_loans: active_loans.size,
      active_reservations: @reservations.count(&:active?),
      top_borrowed_books: top_books,
      most_active_member: {
        member: most_active_member_obj,
        borrow_count: most_active_member ? most_active_member[1] : 0
      }
    }
  end

  def cleanup_expired_reservations(current_date = Time.now)
    expired_count = @reservations.count { |r| r.expired?(current_date) }
    @reservations.reject! { |r| r.expired?(current_date) }
    
    if expired_count > 0
      @logger.log_operation("Expired reservations cleaned up", {count: expired_count})
      save_data
    end
    
    expired_count
  end

  def get_member_history(member_id)
    member = find_member_by_id(member_id)
    raise "Member with ID #{member_id} not found" unless member
    
    member.borrowing_history
  end

  private

  def load_data
    @books = @persistence.load_books
    @members = @persistence.load_members
    @loans = @persistence.load_loans
    @reservations = @persistence.load_reservations
    @logger.log_operation("Data loaded from storage")
  end

  def save_data
    @persistence.save_books(@books)
    @persistence.save_members(@members)
    @persistence.save_loans(@loans)
    @persistence.save_reservations(@reservations)
  end

  def find_book_by_isbn(isbn)
    @books.find { |book| book.isbn == isbn }
  end

  def find_member_by_id(id)
    @members.find { |member| member.id == id }
  end

  def generate_loan_id
    "LOAN_#{Time.now.strftime('%Y%m%d_%H%M%S')}_#{rand(1000..9999)}"
  end

  def generate_reservation_id
    "RES_#{Time.now.strftime('%Y%m%d_%H%M%S')}_#{rand(1000..9999)}"
  end

  def process_next_reservation(isbn)
    next_reservation = @reservations
      .select { |r| r.book_isbn == isbn && r.active? }
      .sort_by(&:reservation_date)
      .first
    
    if next_reservation
      @logger.log_operation("Next reservation notified", {
        member_id: next_reservation.member_id,
        isbn: isbn,
        reservation_id: next_reservation.id
      })
    end
  end
end