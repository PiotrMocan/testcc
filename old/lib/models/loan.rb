class Loan
  LATE_FEE_PER_DAY = 10.0
  BORROWING_PERIOD_DAYS = 14

  attr_accessor :id, :book_isbn, :member_id, :checkout_date, :due_date, :return_date

  def initialize(id:, book_isbn:, member_id:, checkout_date: Time.now)
    raise ArgumentError, "ID cannot be empty" if id.nil? || id.to_s.strip.empty?
    raise ArgumentError, "Book ISBN cannot be empty" if book_isbn.nil? || book_isbn.strip.empty?
    raise ArgumentError, "Member ID cannot be empty" if member_id.nil? || member_id.to_s.strip.empty?

    @id = id
    @book_isbn = book_isbn
    @member_id = member_id
    @checkout_date = checkout_date.is_a?(Time) ? checkout_date : Time.parse(checkout_date)
    @due_date = @checkout_date + (BORROWING_PERIOD_DAYS * 24 * 60 * 60)
    @return_date = nil
  end

  def return_book(return_date = Time.now)
    @return_date = return_date.is_a?(Time) ? return_date : Time.parse(return_date)
  end

  def active?
    @return_date.nil?
  end

  def overdue?(current_date = Time.now)
    active? && @due_date < current_date
  end

  def days_overdue(current_date = Time.now)
    return 0 unless overdue?(current_date)
    ((current_date - @due_date) / (24 * 60 * 60)).ceil
  end

  def late_fee(current_date = Time.now)
    days_overdue(current_date) * LATE_FEE_PER_DAY
  end

  def to_hash
    {
      id: @id,
      book_isbn: @book_isbn,
      member_id: @member_id,
      checkout_date: @checkout_date.to_s,
      due_date: @due_date.to_s,
      return_date: @return_date&.to_s
    }
  end

  def self.from_hash(hash)
    loan = allocate
    loan.id = hash['id'] || hash[:id]
    loan.book_isbn = hash['book_isbn'] || hash[:book_isbn]
    loan.member_id = hash['member_id'] || hash[:member_id]
    loan.checkout_date = Time.parse(hash['checkout_date'] || hash[:checkout_date])
    loan.due_date = Time.parse(hash['due_date'] || hash[:due_date])
    loan.return_date = (hash['return_date'] || hash[:return_date]) ? Time.parse(hash['return_date'] || hash[:return_date]) : nil
    loan
  end
end