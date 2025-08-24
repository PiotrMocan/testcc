require_relative '../modules/validator'

class Book
  attr_accessor :isbn, :title, :author, :publication_year, :total_copies, :available_copies, :genre

  def initialize(isbn:, title:, author:, publication_year:, total_copies: 1, genre: nil)
    raise ArgumentError, "Invalid ISBN format" unless Validator.valid_isbn?(isbn)
    raise ArgumentError, "Title cannot be empty" if title.nil? || title.strip.empty?
    raise ArgumentError, "Author cannot be empty" if author.nil? || author.strip.empty?
    raise ArgumentError, "Invalid publication year" unless valid_year?(publication_year)
    raise ArgumentError, "Total copies must be positive" unless total_copies.positive?

    @isbn = isbn.gsub(/[-\s]/, '')
    @title = title.strip
    @author = author.strip
    @publication_year = publication_year
    @total_copies = total_copies
    @available_copies = total_copies
    @genre = genre&.strip
  end

  def checkout_copy
    raise StandardError, "No copies available for checkout" if @available_copies <= 0
    @available_copies -= 1
  end

  def return_copy
    raise StandardError, "Cannot return more copies than total" if @available_copies >= @total_copies
    @available_copies += 1
  end

  def available?
    @available_copies > 0
  end

  def add_copies(count)
    raise ArgumentError, "Count must be positive" unless count.positive?
    @total_copies += count
    @available_copies += count
  end

  def remove_copies(count)
    raise ArgumentError, "Count must be positive" unless count.positive?
    raise StandardError, "Cannot remove more copies than available" if count > @available_copies
    @total_copies -= count
    @available_copies -= count
  end

  def to_hash
    {
      isbn: @isbn,
      title: @title,
      author: @author,
      publication_year: @publication_year,
      total_copies: @total_copies,
      available_copies: @available_copies,
      genre: @genre
    }
  end

  def self.from_hash(hash)
    book = allocate
    book.instance_variable_set(:@isbn, hash['isbn'])
    book.instance_variable_set(:@title, hash['title'])
    book.instance_variable_set(:@author, hash['author'])
    book.instance_variable_set(:@publication_year, hash['publication_year'])
    book.instance_variable_set(:@total_copies, hash['total_copies'])
    book.instance_variable_set(:@available_copies, hash['available_copies'])
    book.instance_variable_set(:@genre, hash['genre'])
    book
  end

  def ==(other)
    return false unless other.is_a?(Book)
    @isbn == other.isbn
  end

  def eql?(other)
    self == other
  end

  def hash
    @isbn.hash
  end

  def to_s
    "#{@title} by #{@author} (ISBN: #{@isbn})"
  end

  private

  def valid_year?(year)
    return false unless year.is_a?(Integer)
    year > 0 && year <= Date.today.year
  end
end