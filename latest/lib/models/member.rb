require_relative '../modules/validator'
require 'securerandom'
require 'date'

class Member
  attr_accessor :id, :name, :email, :registration_date, :borrowing_history

  def initialize(name:, email:, id: nil)
    raise ArgumentError, "Name cannot be empty" if name.nil? || name.strip.empty?
    
    clean_email = email&.downcase&.strip
    raise ArgumentError, "Invalid email format" unless Validator.valid_email?(clean_email)

    @id = id || SecureRandom.uuid
    @name = name.strip
    @email = clean_email
    @registration_date = Date.today
    @borrowing_history = []
  end

  def add_to_history(loan_record)
    @borrowing_history << loan_record
  end

  def current_loans
    @borrowing_history.select { |loan| loan[:return_date].nil? }
  end

  def overdue_loans(current_date = Date.today)
    current_loans.select { |loan| Date.parse(loan[:due_date]) < current_date }
  end

  def total_books_borrowed
    @borrowing_history.length
  end

  def books_currently_borrowed
    current_loans.length
  end

  def has_overdue_books?(current_date = Date.today)
    overdue_loans(current_date).any?
  end

  def calculate_late_fees(current_date = Date.today)
    total_fees = 0
    overdue_loans(current_date).each do |loan|
      due_date = Date.parse(loan[:due_date])
      days_overdue = (current_date - due_date).to_i
      total_fees += days_overdue * 10
    end
    total_fees
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
    member.instance_variable_set(:@id, hash[:id] || hash['id'])
    member.instance_variable_set(:@name, hash[:name] || hash['name'])
    member.instance_variable_set(:@email, hash[:email] || hash['email'])
    member.instance_variable_set(:@registration_date, Date.parse(hash[:registration_date] || hash['registration_date']))
    member.instance_variable_set(:@borrowing_history, hash[:borrowing_history] || hash['borrowing_history'] || [])
    member
  end

  def ==(other)
    return false unless other.is_a?(Member)
    @id == other.id
  end

  def eql?(other)
    self == other
  end

  def hash
    @id.hash
  end

  def to_s
    "#{@name} (#{@email})"
  end
end