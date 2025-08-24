require_relative '../../lib/models/book'
require_relative '../shared_examples'
require 'date'

RSpec.describe Book do
  let(:valid_attributes) do
    {
      isbn: '9780306406157',
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      publication_year: 1925,
      total_copies: 3,
      genre: 'Fiction'
    }
  end

  let(:expected_hash_keys) { [:isbn, :title, :author, :publication_year, :total_copies, :available_copies, :genre] }

  describe 'initialization' do
    it 'creates a book with valid attributes' do
      book = Book.new(**valid_attributes)
      expect(book.isbn).to eq('9780306406157')
      expect(book.title).to eq('The Great Gatsby')
      expect(book.author).to eq('F. Scott Fitzgerald')
      expect(book.publication_year).to eq(1925)
      expect(book.total_copies).to eq(3)
      expect(book.available_copies).to eq(3)
      expect(book.genre).to eq('Fiction')
    end

    it 'strips whitespace from string attributes' do
      book = Book.new(
        isbn: ' 9780306406157 ',
        title: '  The Great Gatsby  ',
        author: '  F. Scott Fitzgerald  ',
        publication_year: 1925,
        genre: '  Fiction  '
      )
      expect(book.isbn).to eq('9780306406157')
      expect(book.title).to eq('The Great Gatsby')
      expect(book.author).to eq('F. Scott Fitzgerald')
      expect(book.genre).to eq('Fiction')
    end

    it 'defaults total_copies to 1' do
      book = Book.new(
        isbn: '9780306406157',
        title: 'Title',
        author: 'Author',
        publication_year: 2020
      )
      expect(book.total_copies).to eq(1)
      expect(book.available_copies).to eq(1)
    end

    it_behaves_like "validates presence of", :title
    it_behaves_like "validates presence of", :author

    it 'validates ISBN format' do
      expect {
        Book.new(**valid_attributes.merge(isbn: 'invalid'))
      }.to raise_error(ArgumentError, "Invalid ISBN format")
    end

    it 'validates publication year is positive' do
      expect {
        Book.new(**valid_attributes.merge(publication_year: -1))
      }.to raise_error(ArgumentError, "Invalid publication year")
    end

    it 'validates publication year is not in future' do
      future_year = Date.today.year + 1
      expect {
        Book.new(**valid_attributes.merge(publication_year: future_year))
      }.to raise_error(ArgumentError, "Invalid publication year")
    end

    it 'validates total_copies is positive' do
      expect {
        Book.new(**valid_attributes.merge(total_copies: 0))
      }.to raise_error(ArgumentError, "Total copies must be positive")
    end
  end

  describe 'copy management' do
    let(:book) { Book.new(**valid_attributes) }

    describe '#checkout_copy' do
      it 'decreases available copies' do
        expect { book.checkout_copy }.to change(book, :available_copies).by(-1)
      end

      it 'raises error when no copies available' do
        3.times { book.checkout_copy }
        expect { book.checkout_copy }.to raise_error(StandardError, "No copies available for checkout")
      end
    end

    describe '#return_copy' do
      before { book.checkout_copy }

      it 'increases available copies' do
        expect { book.return_copy }.to change(book, :available_copies).by(1)
      end

      it 'raises error when trying to return more than total' do
        book.return_copy  # First return should work (2->3 available)
        expect { book.return_copy }.to raise_error(StandardError, "Cannot return more copies than total")
      end
    end

    describe '#available?' do
      it 'returns true when copies are available' do
        expect(book.available?).to be true
      end

      it 'returns false when no copies available' do
        3.times { book.checkout_copy }
        expect(book.available?).to be false
      end
    end

    describe '#add_copies' do
      it 'increases total and available copies' do
        expect { book.add_copies(2) }.to change(book, :total_copies).by(2)
                                   .and change(book, :available_copies).by(2)
      end

      it 'raises error for non-positive count' do
        expect { book.add_copies(0) }.to raise_error(ArgumentError, "Count must be positive")
        expect { book.add_copies(-1) }.to raise_error(ArgumentError, "Count must be positive")
      end
    end

    describe '#remove_copies' do
      it 'decreases total and available copies' do
        expect { book.remove_copies(1) }.to change(book, :total_copies).by(-1)
                                      .and change(book, :available_copies).by(-1)
      end

      it 'raises error when trying to remove more than available' do
        book.checkout_copy
        expect { book.remove_copies(3) }.to raise_error(StandardError, "Cannot remove more copies than available")
      end

      it 'raises error for non-positive count' do
        expect { book.remove_copies(0) }.to raise_error(ArgumentError, "Count must be positive")
      end
    end
  end

  it_behaves_like "a persistable object", Book

  describe 'equality and hashing' do
    let(:book1) { Book.new(**valid_attributes) }
    let(:book2) { Book.new(**valid_attributes) }
    let(:different_book) { Book.new(**valid_attributes.merge(isbn: '9780140449136')) }

    it 'treats books with same ISBN as equal' do
      expect(book1).to eq(book2)
      expect(book1.eql?(book2)).to be true
    end

    it 'treats books with different ISBN as not equal' do
      expect(book1).not_to eq(different_book)
    end

    it 'has consistent hash values for equal objects' do
      expect(book1.hash).to eq(book2.hash)
    end
  end

  describe '#to_s' do
    let(:book) { Book.new(**valid_attributes) }

    it 'returns readable string representation' do
      expect(book.to_s).to eq("The Great Gatsby by F. Scott Fitzgerald (ISBN: 9780306406157)")
    end
  end
end