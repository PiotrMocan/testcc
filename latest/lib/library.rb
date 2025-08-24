require_relative 'services/data_store'
require_relative 'models/book'
require_relative 'models/member'
require_relative 'models/loan'
require_relative 'models/reservation'
require_relative 'modules/logger'
require 'date'

class Library
  def initialize(data_dir = nil)
    @data_store = DataStore.new(data_dir)
    LibraryLogger.info("Library system initialized")
  end

  def add_book(isbn:, title:, author:, publication_year:, total_copies: 1, genre: nil)
    existing_book = @data_store.find_book(isbn)
    
    if existing_book
      existing_book.add_copies(total_copies)
      @data_store.save_book(existing_book)
      LibraryLogger.info("Added copies to existing book", isbn: isbn, copies_added: total_copies)
    else
      book = Book.new(
        isbn: isbn,
        title: title,
        author: author,
        publication_year: publication_year,
        total_copies: total_copies,
        genre: genre
      )
      @data_store.save_book(book)
      LibraryLogger.info("New book added", isbn: isbn, title: title)
    end
  end

  def remove_book(isbn)
    book = @data_store.find_book(isbn)
    raise ArgumentError, "Book not found" unless book

    active_loans = @data_store.loans_for_book(isbn).select(&:active?)
    raise StandardError, "Cannot remove book with active loans" if active_loans.any?

    @data_store.remove_book(isbn)
    LibraryLogger.info("Book removed", isbn: isbn)
    book
  end

  def register_member(name:, email:)
    member = Member.new(name: name, email: email)
    @data_store.save_member(member)
    LibraryLogger.info("New member registered", member_id: member.id, name: name)
    member
  end

  def checkout_book(isbn:, member_id:)
    book = @data_store.find_book(isbn)
    raise ArgumentError, "Book not found" unless book

    member = @data_store.find_member(member_id)
    raise ArgumentError, "Member not found" unless member

    if book.available?
      book.checkout_copy
      loan = Loan.new(book_isbn: isbn, member_id: member_id)
      
      member.add_to_history({
        book_isbn: isbn,
        checkout_date: loan.checkout_date.to_s,
        due_date: loan.due_date.to_s,
        return_date: nil
      })

      @data_store.save_book(book)
      @data_store.save_loan(loan)
      @data_store.save_member(member)

      LibraryLogger.info("Book checked out", isbn: isbn, member_id: member_id, loan_id: loan.id)
      loan
    else
      reservation = reserve_book(isbn: isbn, member_id: member_id)
      raise StandardError, "No copies available. Book reserved for you (Reservation ID: #{reservation.id})"
    end
  end

  def return_book(isbn:, member_id:, return_date: Date.today)
    book = @data_store.find_book(isbn)
    raise ArgumentError, "Book not found" unless book

    member = @data_store.find_member(member_id)
    raise ArgumentError, "Member not found" unless member

    active_loan = @data_store.loans_for_member(member_id)
                             .find { |loan| loan.book_isbn == isbn && loan.active? }
    raise ArgumentError, "No active loan found for this book and member" unless active_loan

    active_loan.return_book(return_date)
    book.return_copy

    member.borrowing_history.each do |record|
      if record[:book_isbn] == isbn && record[:return_date].nil?
        record[:return_date] = return_date.to_s
        break
      end
    end

    @data_store.save_book(book)
    @data_store.save_loan(active_loan)
    @data_store.save_member(member)

    process_reservations_for_book(isbn)

    LibraryLogger.info("Book returned", isbn: isbn, member_id: member_id, late_fee: active_loan.late_fee)
    active_loan
  end

  def reserve_book(isbn:, member_id:)
    book = @data_store.find_book(isbn)
    raise ArgumentError, "Book not found" unless book

    member = @data_store.find_member(member_id)
    raise ArgumentError, "Member not found" unless member

    existing_reservation = @data_store.reservations_for_book(isbn)
                                     .find { |r| r.member_id == member_id && r.active? }
    raise StandardError, "Member already has an active reservation for this book" if existing_reservation

    reservation = Reservation.new(book_isbn: isbn, member_id: member_id)
    @data_store.save_reservation(reservation)

    LibraryLogger.info("Book reserved", isbn: isbn, member_id: member_id, reservation_id: reservation.id)
    reservation
  end

  def search_books(query:)
    query_downcase = query.downcase
    @data_store.all_books.select do |book|
      book.title.downcase.include?(query_downcase) ||
      book.author.downcase.include?(query_downcase) ||
      (book.genre && book.genre.downcase.include?(query_downcase))
    end
  end

  def members_with_overdue_books(current_date = Date.today)
    members_with_overdue = []
    
    @data_store.all_members.each do |member|
      overdue_loans = member.overdue_loans(current_date)
      if overdue_loans.any?
        members_with_overdue << {
          member: member,
          overdue_loans: overdue_loans,
          total_late_fees: member.calculate_late_fees(current_date)
        }
      end
    end
    
    members_with_overdue
  end

  def statistics
    loans = @data_store.all_loans
    members = @data_store.all_members

    book_borrow_counts = Hash.new(0)
    loans.each { |loan| book_borrow_counts[loan.book_isbn] += 1 }

    top_books = book_borrow_counts.sort_by { |_, count| -count }
                                 .first(5)
                                 .map do |isbn, count|
      book = @data_store.find_book(isbn)
      { book: book, borrow_count: count }
    end

    most_active_reader = members.max_by(&:total_books_borrowed)

    {
      top_5_most_borrowed_books: top_books,
      most_active_reader: most_active_reader,
      total_books: @data_store.all_books.count,
      total_members: members.count,
      active_loans: @data_store.active_loans.count,
      active_reservations: @data_store.active_reservations.count
    }
  end

  def get_member_borrowing_history(member_id)
    member = @data_store.find_member(member_id)
    raise ArgumentError, "Member not found" unless member

    history_with_books = member.borrowing_history.map do |record|
      book = @data_store.find_book(record[:book_isbn])
      record.merge(book_title: book&.title, book_author: book&.author)
    end

    {
      member: member,
      borrowing_history: history_with_books,
      current_loans_count: member.books_currently_borrowed,
      total_books_borrowed: member.total_books_borrowed
    }
  end

  def cleanup_expired_reservations(current_date = Date.today)
    expired_count = 0
    @data_store.all_reservations.each do |reservation|
      if reservation.expired?(current_date)
        @data_store.remove_reservation(reservation.id)
        expired_count += 1
        LibraryLogger.info("Expired reservation removed", reservation_id: reservation.id, book_isbn: reservation.book_isbn)
      end
    end
    expired_count
  end

  private

  def process_reservations_for_book(isbn)
    reservations = @data_store.reservations_for_book(isbn)
                              .sort_by(&:reservation_date)

    reservations.first&.fulfill!
    if reservations.first
      @data_store.save_reservation(reservations.first)
      LibraryLogger.info("Reservation fulfilled", reservation_id: reservations.first.id, book_isbn: isbn)
    end
  end
end