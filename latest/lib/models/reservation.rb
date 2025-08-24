require 'date'
require 'securerandom'

class Reservation
  attr_accessor :id, :book_isbn, :member_id, :reservation_date, :expiration_date, :fulfilled

  HOLD_PERIOD_DAYS = 3

  def initialize(book_isbn:, member_id:, reservation_date: Date.today, id: nil)
    raise ArgumentError, "Book ISBN cannot be empty" if book_isbn.nil? || book_isbn.strip.empty?
    raise ArgumentError, "Member ID cannot be empty" if member_id.nil? || member_id.strip.empty?

    @id = id || SecureRandom.uuid
    @book_isbn = book_isbn.strip
    @member_id = member_id.strip
    @reservation_date = reservation_date.is_a?(String) ? Date.parse(reservation_date) : reservation_date
    @expiration_date = @reservation_date + HOLD_PERIOD_DAYS
    @fulfilled = false
  end

  def fulfill!
    raise StandardError, "Reservation already fulfilled" if @fulfilled
    @fulfilled = true
  end

  def expired?(current_date = Date.today)
    current_date > @expiration_date && !@fulfilled
  end

  def active?
    !@fulfilled && !expired?
  end

  def days_until_expiration(current_date = Date.today)
    return 0 if expired?(current_date) || @fulfilled
    (@expiration_date - current_date).to_i
  end

  def to_hash
    {
      id: @id,
      book_isbn: @book_isbn,
      member_id: @member_id,
      reservation_date: @reservation_date.to_s,
      expiration_date: @expiration_date.to_s,
      fulfilled: @fulfilled
    }
  end

  def self.from_hash(hash)
    reservation = allocate
    reservation.instance_variable_set(:@id, hash['id'])
    reservation.instance_variable_set(:@book_isbn, hash['book_isbn'])
    reservation.instance_variable_set(:@member_id, hash['member_id'])
    reservation.instance_variable_set(:@reservation_date, Date.parse(hash['reservation_date']))
    reservation.instance_variable_set(:@expiration_date, Date.parse(hash['expiration_date']))
    reservation.instance_variable_set(:@fulfilled, hash['fulfilled'] || false)
    reservation
  end

  def ==(other)
    return false unless other.is_a?(Reservation)
    @id == other.id
  end

  def eql?(other)
    self == other
  end

  def hash
    @id.hash
  end

  def to_s
    status = if @fulfilled
               "fulfilled"
             elsif expired?
               "expired"
             else
               "active (expires #{@expiration_date})"
             end
    "Reservation #{@id}: Book #{@book_isbn} for Member #{@member_id}, #{status}"
  end
end