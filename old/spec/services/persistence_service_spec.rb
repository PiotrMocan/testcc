require 'spec_helper'

RSpec.describe PersistenceService do
  let(:test_data_dir) { 'test_data' }
  let(:books_file) { File.join(test_data_dir, 'books.json') }
  let(:members_file) { File.join(test_data_dir, 'members.json') }
  let(:loans_file) { File.join(test_data_dir, 'loans.json') }
  let(:reservations_file) { File.join(test_data_dir, 'reservations.json') }

  let(:sample_book) do
    Book.new(
      isbn: '9780132350884',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      publication_year: 2008,
      total_copies: 3,
      genre: 'Programming'
    )
  end

  let(:sample_member) do
    Member.new(
      id: 'MEM001',
      name: 'John Doe',
      email: 'john@example.com'
    )
  end

  let(:sample_loan) do
    Loan.new(
      id: 'LOAN_001',
      book_isbn: '9780132350884',
      member_id: 'MEM001'
    )
  end

  let(:sample_reservation) do
    Reservation.new(
      id: 'RES_001',
      book_isbn: '9780132350884',
      member_id: 'MEM001'
    )
  end

  before do
    stub_const('PersistenceService::DATA_DIR', test_data_dir)
    stub_const('PersistenceService::BOOKS_FILE', books_file)
    stub_const('PersistenceService::MEMBERS_FILE', members_file)
    stub_const('PersistenceService::LOANS_FILE', loans_file)
    stub_const('PersistenceService::RESERVATIONS_FILE', reservations_file)
    
    allow(FileUtils).to receive(:mkdir_p)
    allow(File).to receive(:write)
    allow(File).to receive(:read)
    allow(File).to receive(:exist?).and_return(true)
    allow(Dir).to receive(:exist?).and_return(true)
  end

  subject { described_class.new }

  describe '#initialize' do
    it 'creates data directory if it does not exist' do
      allow(Dir).to receive(:exist?).with(test_data_dir).and_return(false)
      expect(FileUtils).to receive(:mkdir_p).with(test_data_dir)
      
      described_class.new
    end

    it 'creates empty JSON files if they do not exist' do
      allow(File).to receive(:exist?).and_return(false)
      expect(File).to receive(:write).with(books_file, '[]')
      expect(File).to receive(:write).with(members_file, '[]')
      expect(File).to receive(:write).with(loans_file, '[]')
      expect(File).to receive(:write).with(reservations_file, '[]')
      
      described_class.new
    end
  end

  describe '#save_books and #load_books' do
    let(:books) { [sample_book] }

    it 'saves books to JSON file' do
      expect(File).to receive(:write).with(books_file, kind_of(String))
      subject.save_books(books)
    end

    it 'loads books from JSON file' do
      json_data = JSON.pretty_generate([sample_book.to_hash])
      allow(File).to receive(:read).with(books_file).and_return(json_data)
      
      loaded_books = subject.load_books
      expect(loaded_books).to be_an(Array)
      expect(loaded_books.first).to be_a(Book)
      expect(loaded_books.first.isbn).to eq(sample_book.isbn)
    end

    it 'returns empty array when file is empty' do
      allow(File).to receive(:read).with(books_file).and_return('')
      
      loaded_books = subject.load_books
      expect(loaded_books).to eq([])
    end

    it 'returns empty array when file does not exist' do
      allow(File).to receive(:exist?).with(books_file).and_return(false)
      
      loaded_books = subject.load_books
      expect(loaded_books).to eq([])
    end
  end

  describe '#save_members and #load_members' do
    let(:members) { [sample_member] }

    it 'saves members to JSON file' do
      expect(File).to receive(:write).with(members_file, kind_of(String))
      subject.save_members(members)
    end

    it 'loads members from JSON file' do
      json_data = JSON.pretty_generate([sample_member.to_hash])
      allow(File).to receive(:read).with(members_file).and_return(json_data)
      
      loaded_members = subject.load_members
      expect(loaded_members).to be_an(Array)
      expect(loaded_members.first).to be_a(Member)
      expect(loaded_members.first.id).to eq(sample_member.id)
    end
  end

  describe '#save_loans and #load_loans' do
    let(:loans) { [sample_loan] }

    it 'saves loans to JSON file' do
      expect(File).to receive(:write).with(loans_file, kind_of(String))
      subject.save_loans(loans)
    end

    it 'loads loans from JSON file' do
      json_data = JSON.pretty_generate([sample_loan.to_hash])
      allow(File).to receive(:read).with(loans_file).and_return(json_data)
      
      loaded_loans = subject.load_loans
      expect(loaded_loans).to be_an(Array)
      expect(loaded_loans.first).to be_a(Loan)
      expect(loaded_loans.first.id).to eq(sample_loan.id)
    end
  end

  describe '#save_reservations and #load_reservations' do
    let(:reservations) { [sample_reservation] }

    it 'saves reservations to JSON file' do
      expect(File).to receive(:write).with(reservations_file, kind_of(String))
      subject.save_reservations(reservations)
    end

    it 'loads reservations from JSON file' do
      json_data = JSON.pretty_generate([sample_reservation.to_hash])
      allow(File).to receive(:read).with(reservations_file).and_return(json_data)
      
      loaded_reservations = subject.load_reservations
      expect(loaded_reservations).to be_an(Array)
      expect(loaded_reservations.first).to be_a(Reservation)
      expect(loaded_reservations.first.id).to eq(sample_reservation.id)
    end
  end

  describe '#backup_data' do
    it 'creates backup directory with timestamp' do
      allow(Time).to receive(:now).and_return(Time.new(2023, 6, 15, 10, 30, 45))
      expected_backup_dir = File.join(test_data_dir, 'backup_20230615_103045')
      
      expect(FileUtils).to receive(:mkdir_p).with(expected_backup_dir)
      expect(FileUtils).to receive(:cp).exactly(4).times
      
      backup_dir = subject.backup_data
      expect(backup_dir).to eq(expected_backup_dir)
    end

    it 'only copies existing files' do
      allow(File).to receive(:exist?).with(books_file).and_return(true)
      allow(File).to receive(:exist?).with(members_file).and_return(false)
      allow(File).to receive(:exist?).with(loans_file).and_return(true)
      allow(File).to receive(:exist?).with(reservations_file).and_return(false)
      
      expect(FileUtils).to receive(:cp).with(books_file, anything)
      expect(FileUtils).to receive(:cp).with(loans_file, anything)
      expect(FileUtils).not_to receive(:cp).with(members_file, anything)
      expect(FileUtils).not_to receive(:cp).with(reservations_file, anything)
      
      subject.backup_data
    end
  end

  describe 'error handling' do
    it 'raises error when save fails' do
      allow(File).to receive(:write).and_raise(StandardError.new("Disk full"))
      
      expect {
        subject.save_books([sample_book])
      }.to raise_error(/Failed to save data.*Disk full/)
    end

    it 'raises error when JSON parsing fails' do
      allow(File).to receive(:read).with(books_file).and_return('invalid json')
      
      expect {
        subject.load_books
      }.to raise_error(/Failed to parse JSON/)
    end

    it 'raises error when file read fails' do
      allow(File).to receive(:read).and_raise(StandardError.new("Permission denied"))
      
      expect {
        subject.load_books
      }.to raise_error(/Failed to load data.*Permission denied/)
    end
  end
end