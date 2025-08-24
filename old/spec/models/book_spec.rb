require 'spec_helper'

RSpec.describe Book do
  let(:valid_attributes) do
    {
      isbn: '9780132350884',
      title: 'The Clean Coder',
      author: 'Robert C. Martin',
      publication_year: 2011,
      total_copies: 5,
      genre: 'Programming'
    }
  end

  subject { described_class.new(**valid_attributes) }

  it_behaves_like "a valid model"

  describe '#initialize' do
    context 'with valid attributes' do
      it 'creates a book with all attributes' do
        expect(subject.isbn).to eq('9780132350884')
        expect(subject.title).to eq('The Clean Coder')
        expect(subject.author).to eq('Robert C. Martin')
        expect(subject.publication_year).to eq(2011)
        expect(subject.total_copies).to eq(5)
        expect(subject.available_copies).to eq(5)
        expect(subject.genre).to eq('Programming')
      end

      it 'strips whitespace from text fields' do
        book = described_class.new(
          **valid_attributes.merge(
            title: '  Clean Code  ',
            author: '  Robert Martin  ',
            genre: '  Programming  '
          )
        )
        
        expect(book.title).to eq('Clean Code')
        expect(book.author).to eq('Robert Martin')
        expect(book.genre).to eq('Programming')
      end
    end

    context 'with invalid attributes' do
      it 'raises error for invalid ISBN' do
        expect {
          described_class.new(**valid_attributes.merge(isbn: 'invalid'))
        }.to raise_error(ArgumentError, "Invalid ISBN format")
      end

      it 'raises error for empty title' do
        expect {
          described_class.new(**valid_attributes.merge(title: ''))
        }.to raise_error(ArgumentError, "Title cannot be empty")
      end

      it 'raises error for nil title' do
        expect {
          described_class.new(**valid_attributes.merge(title: nil))
        }.to raise_error(ArgumentError, "Title cannot be empty")
      end

      it 'raises error for empty author' do
        expect {
          described_class.new(**valid_attributes.merge(author: ''))
        }.to raise_error(ArgumentError, "Author cannot be empty")
      end

      it 'raises error for invalid publication year' do
        expect {
          described_class.new(**valid_attributes.merge(publication_year: 1700))
        }.to raise_error(ArgumentError, "Publication year must be between 1800 and current year")
      end

      it 'raises error for future publication year' do
        expect {
          described_class.new(**valid_attributes.merge(publication_year: Time.now.year + 1))
        }.to raise_error(ArgumentError, "Publication year must be between 1800 and current year")
      end

      it 'raises error for zero or negative copies' do
        expect {
          described_class.new(**valid_attributes.merge(total_copies: 0))
        }.to raise_error(ArgumentError, "Total copies must be positive")
      end

      it 'raises error for empty genre' do
        expect {
          described_class.new(**valid_attributes.merge(genre: ''))
        }.to raise_error(ArgumentError, "Genre cannot be empty")
      end
    end
  end

  describe '#available?' do
    it 'returns true when copies are available' do
      expect(subject.available?).to be true
    end

    it 'returns false when no copies are available' do
      subject.available_copies = 0
      expect(subject.available?).to be false
    end
  end

  describe '#checkout' do
    context 'when copies are available' do
      it 'decreases available copies by 1' do
        expect { subject.checkout }.to change { subject.available_copies }.by(-1)
      end

      it 'does not affect total copies' do
        expect { subject.checkout }.not_to change { subject.total_copies }
      end
    end

    context 'when no copies are available' do
      it 'raises error' do
        subject.available_copies = 0
        expect { subject.checkout }.to raise_error("No copies available")
      end
    end
  end

  describe '#return_book' do
    context 'when book is checked out' do
      before { subject.checkout }

      it 'increases available copies by 1' do
        expect { subject.return_book }.to change { subject.available_copies }.by(1)
      end
    end

    context 'when all copies are already available' do
      it 'raises error' do
        expect { subject.return_book }.to raise_error("All copies already returned")
      end
    end
  end

  describe '#to_hash and .from_hash' do
    it 'serializes to hash correctly' do
      hash = subject.to_hash
      
      expect(hash).to include(
        isbn: '9780132350884',
        title: 'The Clean Coder',
        author: 'Robert C. Martin',
        publication_year: 2011,
        total_copies: 5,
        available_copies: 5,
        genre: 'Programming'
      )
    end

    it 'deserializes from hash correctly' do
      hash = subject.to_hash
      restored_book = described_class.from_hash(hash)
      
      expect(restored_book.isbn).to eq(subject.isbn)
      expect(restored_book.title).to eq(subject.title)
      expect(restored_book.author).to eq(subject.author)
      expect(restored_book.publication_year).to eq(subject.publication_year)
      expect(restored_book.total_copies).to eq(subject.total_copies)
      expect(restored_book.available_copies).to eq(subject.available_copies)
      expect(restored_book.genre).to eq(subject.genre)
    end

    it 'handles string keys from JSON' do
      hash = {
        'isbn' => '9780132350884',
        'title' => 'The Clean Coder',
        'author' => 'Robert C. Martin',
        'publication_year' => 2011,
        'total_copies' => 5,
        'available_copies' => 3,
        'genre' => 'Programming'
      }
      
      restored_book = described_class.from_hash(hash)
      expect(restored_book.available_copies).to eq(3)
    end
  end
end