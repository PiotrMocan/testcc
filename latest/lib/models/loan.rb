require 'date'
require 'securerandom'

class Loan
  attr_accessor :id, :book_isbn, :member_id, :checkout_date, :due_date, :return_date, :late_fee

  BORROWING_PERIOD_DAYS = 14
  DAILY_LATE_FEE = 10

  def initialize(book_isbn:, member_id:, checkout_date: Date.today, id: nil)
    raise ArgumentError, "Book ISBN cannot be empty" if book_isbn.nil? || book_isbn.strip.empty?
    raise ArgumentError, "Member ID cannot be empty" if member_id.nil? || member_id.strip.empty?

    @id = id || SecureRandom.uuid
    @book_isbn = book_isbn.strip
    @member_id = member_id.strip
    @checkout_date = checkout_date.is_a?(String) ? Date.parse(checkout_date) : checkout_date
    @due_date = @checkout_date + BORROWING_PERIOD_DAYS
    @return_date = nil
    @late_fee = 0
  end

  def return_book(return_date = Date.today)
    raise StandardError, "Book already returned" unless @return_date.nil?
    
    return_date = return_date.is_a?(String) ? Date.parse(return_date) : return_date
    calculate_late_fee(return_date)
    @return_date = return_date
  end

  def overdue?(current_date = Date.today)
    return false unless @return_date.nil?
    current_date > @due_date
  end

  def days_overdue(current_date = Date.today)
    return 0 unless overdue?(current_date)
    (current_date - @due_date).to_i
  end

  def calculate_late_fee(current_date = Date.today)
    return @late_fee unless @return_date.nil?
    
    if current_date > @due_date
      @late_fee = (current_date - @due_date).to_i * DAILY_LATE_FEE
    else
      @late_fee = 0
    end
  end

  def returned?
    !@return_date.nil?
  end

  def active?
    @return_date.nil?
  end

  def to_hash
    {
      id: @id,
      book_isbn: @book_isbn,
      member_id: @member_id,
      checkout_date: @checkout_date.to_s,
      due_date: @due_date.to_s,
      return_date: @return_date&.to_s,
      late_fee: @late_fee
    }
  end

  def self.from_hash(hash)
    loan = allocate
    loan.instance_variable_set(:@id, hash[:id] || hash['id'])
    loan.instance_variable_set(:@book_isbn, hash[:book_isbn] || hash['book_isbn'])
    loan.instance_variable_set(:@member_id, hash[:member_id] || hash['member_id'])
    loan.instance_variable_set(:@checkout_date, Date.parse(hash[:checkout_date] || hash['checkout_date']))
    loan.instance_variable_set(:@due_date, Date.parse(hash[:due_date] || hash['due_date']))
    return_date_str = hash[:return_date] || hash['return_date']
    loan.instance_variable_set(:@return_date, return_date_str ? Date.parse(return_date_str) : nil)
    loan.instance_variable_set(:@late_fee, hash[:late_fee] || hash['late_fee'] || 0)
    loan
  end

  def ==(other)
    return false unless other.is_a?(Loan)
    @id == other.id
  end

  def eql?(other)
    self == other
  end

  def hash
    @id.hash
  end

  def to_s
    status = returned? ? "returned on #{@return_date}" : "due #{@due_date}"
    "Loan #{@id}: Book #{@book_isbn} to Member #{@member_id}, #{status}"
  end
end