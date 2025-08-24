require_relative '../modules/validators'

class Book
  include Validators

  attr_accessor :isbn, :title, :author, :publication_year, :available_copies, :total_copies, :genre

  def initialize(isbn:, title:, author:, publication_year:, total_copies:, genre:)
    raise ArgumentError, "Invalid ISBN format" unless valid_isbn?(isbn)
    raise ArgumentError, "Title cannot be empty" if title.nil? || title.strip.empty?
    raise ArgumentError, "Author cannot be empty" if author.nil? || author.strip.empty?
    raise ArgumentError, "Publication year must be between 1800 and current year" unless valid_year?(publication_year)
    raise ArgumentError, "Total copies must be positive" if total_copies <= 0
    raise ArgumentError, "Genre cannot be empty" if genre.nil? || genre.strip.empty?

    @isbn = isbn
    @title = title.strip
    @author = author.strip
    @publication_year = publication_year
    @total_copies = total_copies
    @available_copies = total_copies
    @genre = genre.strip
  end

  def available?
    @available_copies > 0
  end

  def checkout
    raise "No copies available" unless available?
    @available_copies -= 1
  end

  def return_book
    raise "All copies already returned" if @available_copies >= @total_copies
    @available_copies += 1
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
    book.isbn = hash['isbn'] || hash[:isbn]
    book.title = hash['title'] || hash[:title]
    book.author = hash['author'] || hash[:author]
    book.publication_year = hash['publication_year'] || hash[:publication_year]
    book.total_copies = hash['total_copies'] || hash[:total_copies]
    book.available_copies = hash['available_copies'] || hash[:available_copies]
    book.genre = hash['genre'] || hash[:genre]
    book
  end

  private

  def valid_year?(year)
    year.is_a?(Integer) && year >= 1800 && year <= Time.now.year
  end
end