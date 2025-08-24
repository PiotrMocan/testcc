module Validator
  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i.freeze
  ISBN_10_REGEX = /\A\d{9}[\dX]\z/.freeze
  ISBN_13_REGEX = /\A\d{13}\z/.freeze

  def self.valid_email?(email)
    return false if email.nil? || email.empty?
    !!(email =~ EMAIL_REGEX)
  end

  def self.valid_isbn?(isbn)
    return false if isbn.nil? || isbn.empty?
    
    clean_isbn = isbn.gsub(/[-\s]/, '')
    
    case clean_isbn.length
    when 10
      valid_isbn_10?(clean_isbn)
    when 13
      valid_isbn_13?(clean_isbn)
    else
      false
    end
  end

  private

  def self.valid_isbn_10?(isbn)
    return false unless isbn =~ ISBN_10_REGEX
    
    sum = 0
    (0..8).each do |i|
      sum += isbn[i].to_i * (10 - i)
    end
    
    check_digit = isbn[9]
    calculated_check = (11 - (sum % 11)) % 11
    
    if calculated_check == 10
      check_digit == 'X'
    else
      check_digit.to_i == calculated_check
    end
  end

  def self.valid_isbn_13?(isbn)
    return false unless isbn =~ ISBN_13_REGEX
    
    sum = 0
    (0..11).each do |i|
      multiplier = i.even? ? 1 : 3
      sum += isbn[i].to_i * multiplier
    end
    
    check_digit = isbn[12].to_i
    calculated_check = (10 - (sum % 10)) % 10
    
    check_digit == calculated_check
  end
end