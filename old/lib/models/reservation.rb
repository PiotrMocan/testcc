class Reservation
  HOLD_PERIOD_DAYS = 3

  attr_accessor :id, :book_isbn, :member_id, :reservation_date, :expiration_date, :fulfilled

  def initialize(id:, book_isbn:, member_id:, reservation_date: Time.now)
    raise ArgumentError, "ID cannot be empty" if id.nil? || id.to_s.strip.empty?
    raise ArgumentError, "Book ISBN cannot be empty" if book_isbn.nil? || book_isbn.strip.empty?
    raise ArgumentError, "Member ID cannot be empty" if member_id.nil? || member_id.to_s.strip.empty?

    @id = id
    @book_isbn = book_isbn
    @member_id = member_id
    @reservation_date = reservation_date.is_a?(Time) ? reservation_date : Time.parse(reservation_date)
    @expiration_date = @reservation_date + (HOLD_PERIOD_DAYS * 24 * 60 * 60)
    @fulfilled = false
  end

  def active?(current_date = Time.now)
    !@fulfilled && @expiration_date >= current_date
  end

  def expired?(current_date = Time.now)
    !@fulfilled && @expiration_date < current_date
  end

  def fulfill
    @fulfilled = true
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
    reservation.id = hash['id'] || hash[:id]
    reservation.book_isbn = hash['book_isbn'] || hash[:book_isbn]
    reservation.member_id = hash['member_id'] || hash[:member_id]
    reservation.reservation_date = Time.parse(hash['reservation_date'] || hash[:reservation_date])
    reservation.expiration_date = Time.parse(hash['expiration_date'] || hash[:expiration_date])
    reservation.fulfilled = hash['fulfilled'] || hash[:fulfilled] || false
    reservation
  end
end