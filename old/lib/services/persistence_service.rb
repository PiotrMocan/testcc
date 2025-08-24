require 'json'
require 'fileutils'
require_relative '../models/book'
require_relative '../models/member'
require_relative '../models/loan'
require_relative '../models/reservation'

class PersistenceService
  DATA_DIR = 'data'
  
  BOOKS_FILE = File.join(DATA_DIR, 'books.json')
  MEMBERS_FILE = File.join(DATA_DIR, 'members.json')
  LOANS_FILE = File.join(DATA_DIR, 'loans.json')
  RESERVATIONS_FILE = File.join(DATA_DIR, 'reservations.json')

  def initialize
    ensure_data_directory_exists
    ensure_files_exist
  end

  def save_books(books)
    save_to_file(BOOKS_FILE, books.map(&:to_hash))
  end

  def load_books
    data = load_from_file(BOOKS_FILE)
    return [] if data.empty?
    
    data.map { |book_data| Book.from_hash(book_data) }
  end

  def save_members(members)
    save_to_file(MEMBERS_FILE, members.map(&:to_hash))
  end

  def load_members
    data = load_from_file(MEMBERS_FILE)
    return [] if data.empty?
    
    data.map { |member_data| Member.from_hash(member_data) }
  end

  def save_loans(loans)
    save_to_file(LOANS_FILE, loans.map(&:to_hash))
  end

  def load_loans
    data = load_from_file(LOANS_FILE)
    return [] if data.empty?
    
    data.map { |loan_data| Loan.from_hash(loan_data) }
  end

  def save_reservations(reservations)
    save_to_file(RESERVATIONS_FILE, reservations.map(&:to_hash))
  end

  def load_reservations
    data = load_from_file(RESERVATIONS_FILE)
    return [] if data.empty?
    
    data.map { |reservation_data| Reservation.from_hash(reservation_data) }
  end

  def backup_data
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    backup_dir = File.join(DATA_DIR, "backup_#{timestamp}")
    
    FileUtils.mkdir_p(backup_dir)
    
    [BOOKS_FILE, MEMBERS_FILE, LOANS_FILE, RESERVATIONS_FILE].each do |file|
      if File.exist?(file)
        FileUtils.cp(file, backup_dir)
      end
    end
    
    backup_dir
  end

  private

  def ensure_data_directory_exists
    FileUtils.mkdir_p(DATA_DIR) unless Dir.exist?(DATA_DIR)
  end

  def ensure_files_exist
    [BOOKS_FILE, MEMBERS_FILE, LOANS_FILE, RESERVATIONS_FILE].each do |file|
      unless File.exist?(file)
        File.write(file, '[]')
      end
    end
  end

  def save_to_file(filename, data)
    begin
      File.write(filename, JSON.pretty_generate(data))
    rescue => e
      raise "Failed to save data to #{filename}: #{e.message}"
    end
  end

  def load_from_file(filename)
    begin
      return [] unless File.exist?(filename)
      
      content = File.read(filename)
      return [] if content.strip.empty?
      
      JSON.parse(content)
    rescue JSON::ParserError => e
      raise "Failed to parse JSON from #{filename}: #{e.message}"
    rescue => e
      raise "Failed to load data from #{filename}: #{e.message}"
    end
  end
end