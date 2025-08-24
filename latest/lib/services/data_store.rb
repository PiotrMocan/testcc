require 'json'
require 'fileutils'
require_relative '../modules/logger'
require_relative '../models/book'
require_relative '../models/member'
require_relative '../models/loan'
require_relative '../models/reservation'

class DataStore
  DATA_DIR = 'data'.freeze
  BOOKS_FILE = File.join(DATA_DIR, 'books.json').freeze
  MEMBERS_FILE = File.join(DATA_DIR, 'members.json').freeze
  LOANS_FILE = File.join(DATA_DIR, 'loans.json').freeze
  RESERVATIONS_FILE = File.join(DATA_DIR, 'reservations.json').freeze

  def initialize
    ensure_data_directory
    @books = load_books
    @members = load_members
    @loans = load_loans
    @reservations = load_reservations
  end

  def save_book(book)
    @books[book.isbn] = book
    save_books
    LibraryLogger.info("Book saved", isbn: book.isbn, title: book.title)
  end

  def find_book(isbn)
    @books[isbn]
  end

  def all_books
    @books.values
  end

  def remove_book(isbn)
    book = @books.delete(isbn)
    save_books if book
    LibraryLogger.info("Book removed", isbn: isbn) if book
    book
  end

  def save_member(member)
    @members[member.id] = member
    save_members
    LibraryLogger.info("Member saved", member_id: member.id, name: member.name)
  end

  def find_member(id)
    @members[id]
  end

  def all_members
    @members.values
  end

  def remove_member(id)
    member = @members.delete(id)
    save_members if member
    LibraryLogger.info("Member removed", member_id: id) if member
    member
  end

  def save_loan(loan)
    @loans[loan.id] = loan
    save_loans
    LibraryLogger.info("Loan saved", loan_id: loan.id, book_isbn: loan.book_isbn, member_id: loan.member_id)
  end

  def find_loan(id)
    @loans[id]
  end

  def all_loans
    @loans.values
  end

  def active_loans
    @loans.values.select(&:active?)
  end

  def loans_for_member(member_id)
    @loans.values.select { |loan| loan.member_id == member_id }
  end

  def loans_for_book(isbn)
    @loans.values.select { |loan| loan.book_isbn == isbn }
  end

  def save_reservation(reservation)
    @reservations[reservation.id] = reservation
    save_reservations
    LibraryLogger.info("Reservation saved", reservation_id: reservation.id, book_isbn: reservation.book_isbn, member_id: reservation.member_id)
  end

  def find_reservation(id)
    @reservations[id]
  end

  def all_reservations
    @reservations.values
  end

  def active_reservations
    @reservations.values.select(&:active?)
  end

  def reservations_for_book(isbn)
    @reservations.values.select { |reservation| reservation.book_isbn == isbn && reservation.active? }
  end

  def reservations_for_member(member_id)
    @reservations.values.select { |reservation| reservation.member_id == member_id }
  end

  def remove_reservation(id)
    reservation = @reservations.delete(id)
    save_reservations if reservation
    LibraryLogger.info("Reservation removed", reservation_id: id) if reservation
    reservation
  end

  private

  def ensure_data_directory
    FileUtils.mkdir_p(DATA_DIR) unless Dir.exist?(DATA_DIR)
  end

  def load_books
    return {} unless File.exist?(BOOKS_FILE)
    
    data = JSON.parse(File.read(BOOKS_FILE))
    data.transform_values { |book_data| Book.from_hash(book_data) }
  rescue JSON::ParserError => e
    LibraryLogger.error("Failed to parse books file", error: e.message)
    {}
  rescue => e
    LibraryLogger.error("Failed to load books", error: e.message)
    {}
  end

  def load_members
    return {} unless File.exist?(MEMBERS_FILE)
    
    data = JSON.parse(File.read(MEMBERS_FILE))
    data.transform_values { |member_data| Member.from_hash(member_data) }
  rescue JSON::ParserError => e
    LibraryLogger.error("Failed to parse members file", error: e.message)
    {}
  rescue => e
    LibraryLogger.error("Failed to load members", error: e.message)
    {}
  end

  def load_loans
    return {} unless File.exist?(LOANS_FILE)
    
    data = JSON.parse(File.read(LOANS_FILE))
    data.transform_values { |loan_data| Loan.from_hash(loan_data) }
  rescue JSON::ParserError => e
    LibraryLogger.error("Failed to parse loans file", error: e.message)
    {}
  rescue => e
    LibraryLogger.error("Failed to load loans", error: e.message)
    {}
  end

  def load_reservations
    return {} unless File.exist?(RESERVATIONS_FILE)
    
    data = JSON.parse(File.read(RESERVATIONS_FILE))
    data.transform_values { |reservation_data| Reservation.from_hash(reservation_data) }
  rescue JSON::ParserError => e
    LibraryLogger.error("Failed to parse reservations file", error: e.message)
    {}
  rescue => e
    LibraryLogger.error("Failed to load reservations", error: e.message)
    {}
  end

  def save_books
    save_to_file(BOOKS_FILE, @books.transform_values(&:to_hash))
  end

  def save_members
    save_to_file(MEMBERS_FILE, @members.transform_values(&:to_hash))
  end

  def save_loans
    save_to_file(LOANS_FILE, @loans.transform_values(&:to_hash))
  end

  def save_reservations
    save_to_file(RESERVATIONS_FILE, @reservations.transform_values(&:to_hash))
  end

  def save_to_file(filename, data)
    File.write(filename, JSON.pretty_generate(data))
  rescue => e
    LibraryLogger.error("Failed to save to file", file: filename, error: e.message)
    raise
  end
end