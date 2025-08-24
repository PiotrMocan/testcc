require_relative '../modules/validators'

class Member
  include Validators

  attr_accessor :id, :name, :email, :registration_date, :borrowing_history

  def initialize(id:, name:, email:, registration_date: Time.now)
    raise ArgumentError, "ID cannot be empty" if id.nil? || id.to_s.strip.empty?
    raise ArgumentError, "Name cannot be empty" if name.nil? || name.strip.empty?
    raise ArgumentError, "Invalid email format" unless valid_email?(email)

    @id = id
    @name = name.strip
    @email = email.strip.downcase
    @registration_date = registration_date.is_a?(Time) ? registration_date : Time.parse(registration_date)
    @borrowing_history = []
  end

  def add_to_history(loan_record)
    @borrowing_history << loan_record
  end

  def active_loans
    @borrowing_history.select { |loan| loan[:return_date].nil? }
  end

  def overdue_loans(current_date = Time.now)
    active_loans.select { |loan| loan[:due_date] < current_date }
  end

  def total_borrowed_books
    @borrowing_history.size
  end

  def to_hash
    {
      id: @id,
      name: @name,
      email: @email,
      registration_date: @registration_date.to_s,
      borrowing_history: @borrowing_history
    }
  end

  def self.from_hash(hash)
    member = allocate
    member.id = hash['id'] || hash[:id]
    member.name = hash['name'] || hash[:name]
    member.email = hash['email'] || hash[:email]
    member.registration_date = Time.parse(hash['registration_date'] || hash[:registration_date])
    member.borrowing_history = hash['borrowing_history'] || hash[:borrowing_history] || []
    member
  end
end