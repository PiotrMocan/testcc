module Validators
  def valid_email?(email)
    return false if email.nil? || email.strip.empty?
    
    email_regex = /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/
    email.match?(email_regex)
  end

  def valid_isbn?(isbn)
    return false if isbn.nil? || isbn.strip.empty?
    
    cleaned_isbn = isbn.gsub(/[-\s]/, '')
    
    return false unless [10, 13].include?(cleaned_isbn.length)
    return false unless cleaned_isbn.match?(/\A\d{9}[\dX]\z/) || cleaned_isbn.match?(/\A\d{13}\z/)
    
    if cleaned_isbn.length == 10
      valid_isbn10?(cleaned_isbn)
    else
      valid_isbn13?(cleaned_isbn)
    end
  end

  private

  def valid_isbn10?(isbn)
    sum = 0
    isbn.chars.each_with_index do |char, index|
      digit = char == 'X' ? 10 : char.to_i
      sum += digit * (10 - index)
    end
    (sum % 11).zero?
  end

  def valid_isbn13?(isbn)
    sum = 0
    isbn.chars.each_with_index do |char, index|
      digit = char.to_i
      multiplier = index.even? ? 1 : 3
      sum += digit * multiplier
    end
    (sum % 10).zero?
  end
end