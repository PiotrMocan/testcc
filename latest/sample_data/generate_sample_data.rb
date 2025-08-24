require_relative '../lib/library'
require 'date'

def generate_sample_data
  puts "Generating sample data for Library Management System..."
  
  library = Library.new
  
  # Sample books with various genres
  books_data = [
    {
      isbn: '9780143127741',
      title: 'The Handmaid\'s Tale',
      author: 'Margaret Atwood',
      publication_year: 1985,
      total_copies: 3,
      genre: 'Dystopian Fiction'
    },
    {
      isbn: '9780452284234',
      title: '1984',
      author: 'George Orwell',
      publication_year: 1949,
      total_copies: 4,
      genre: 'Dystopian Fiction'
    },
    {
      isbn: '9780060850524',
      title: 'Brave New World',
      author: 'Aldous Huxley',
      publication_year: 1932,
      total_copies: 2,
      genre: 'Science Fiction'
    },
    {
      isbn: '9780141439518',
      title: 'Pride and Prejudice',
      author: 'Jane Austen',
      publication_year: 1813,
      total_copies: 5,
      genre: 'Romance'
    },
    {
      isbn: '9780385472579',
      title: 'The Kite Runner',
      author: 'Khaled Hosseini',
      publication_year: 2003,
      total_copies: 3,
      genre: 'Historical Fiction'
    },
    {
      isbn: '9780439708180',
      title: 'Harry Potter and the Sorcerer\'s Stone',
      author: 'J.K. Rowling',
      publication_year: 1997,
      total_copies: 6,
      genre: 'Fantasy'
    },
    {
      isbn: '9780544003415',
      title: 'The Lord of the Rings',
      author: 'J.R.R. Tolkien',
      publication_year: 1954,
      total_copies: 4,
      genre: 'Fantasy'
    },
    {
      isbn: '9780062315007',
      title: 'The Alchemist',
      author: 'Paulo Coelho',
      publication_year: 1988,
      total_copies: 3,
      genre: 'Philosophy'
    },
    {
      isbn: '9780316769488',
      title: 'The Catcher in the Rye',
      author: 'J.D. Salinger',
      publication_year: 1951,
      total_copies: 2,
      genre: 'Coming of Age'
    },
    {
      isbn: '9780307887894',
      title: 'Gone Girl',
      author: 'Gillian Flynn',
      publication_year: 2012,
      total_copies: 4,
      genre: 'Mystery Thriller'
    }
  ]
  
  # Add books to library
  books_data.each do |book_data|
    library.add_book(**book_data)
    puts "Added book: #{book_data[:title]} by #{book_data[:author]}"
  end
  
  # Sample members
  members_data = [
    { name: 'Alice Johnson', email: 'alice.johnson@email.com' },
    { name: 'Bob Smith', email: 'bob.smith@email.com' },
    { name: 'Carol Davis', email: 'carol.davis@email.com' },
    { name: 'David Wilson', email: 'david.wilson@email.com' },
    { name: 'Emma Brown', email: 'emma.brown@email.com' },
    { name: 'Frank Miller', email: 'frank.miller@email.com' },
    { name: 'Grace Lee', email: 'grace.lee@email.com' },
    { name: 'Henry Taylor', email: 'henry.taylor@email.com' }
  ]
  
  # Register members
  members = []
  members_data.each do |member_data|
    member = library.register_member(**member_data)
    members << member
    puts "Registered member: #{member_data[:name]}"
  end
  
  # Create some active loans
  active_loans = [
    { isbn: '9780143127741', member_index: 0 }, # Alice borrows Handmaid's Tale
    { isbn: '9780452284234', member_index: 1 }, # Bob borrows 1984
    { isbn: '9780439708180', member_index: 2 }, # Carol borrows Harry Potter
    { isbn: '9780544003415', member_index: 0 }, # Alice borrows LOTR (multiple books)
    { isbn: '9780307887894', member_index: 3 }, # David borrows Gone Girl
  ]
  
  active_loans.each do |loan_data|
    member = members[loan_data[:member_index]]
    library.checkout_book(isbn: loan_data[:isbn], member_id: member.id)
    book_title = books_data.find { |b| b[:isbn] == loan_data[:isbn] }[:title]
    puts "#{member.name} checked out: #{book_title}"
  end
  
  # Create some returned loans with varying return dates (some overdue)
  returned_loans = [
    { isbn: '9780060850524', member_index: 4, days_ago: 5 }, # Emma returned Brave New World on time
    { isbn: '9780141439518', member_index: 5, days_ago: 20 }, # Frank returned Pride and Prejudice late
    { isbn: '9780385472579', member_index: 6, days_ago: 10 }, # Grace returned Kite Runner on time
    { isbn: '9780062315007', member_index: 7, days_ago: 25 }, # Henry returned Alchemist very late
  ]
  
  returned_loans.each do |loan_data|
    member = members[loan_data[:member_index]]
    checkout_date = Date.today - loan_data[:days_ago] - 14 # Checked out days_ago + 14 days ago
    return_date = Date.today - loan_data[:days_ago]
    
    # Simulate loan by creating it with past checkout date
    loan = library.checkout_book(isbn: loan_data[:isbn], member_id: member.id)
    
    # Manually set checkout date for the scenario
    loan.instance_variable_set(:@checkout_date, checkout_date)
    loan.instance_variable_set(:@due_date, checkout_date + 14)
    
    # Return the book
    library.return_book(isbn: loan_data[:isbn], member_id: member.id, return_date: return_date)
    
    book_title = books_data.find { |b| b[:isbn] == loan_data[:isbn] }[:title]
    puts "#{member.name} returned: #{book_title} (#{loan_data[:days_ago]} days ago)"
  end
  
  # Create some reservations
  reservations = [
    { isbn: '9780143127741', member_index: 1 }, # Bob reserves Handmaid's Tale (Alice has it)
    { isbn: '9780439708180', member_index: 3 }, # David reserves Harry Potter (Carol has it)
  ]
  
  reservations.each do |reservation_data|
    member = members[reservation_data[:member_index]]
    begin
      library.reserve_book(isbn: reservation_data[:isbn], member_id: member.id)
      book_title = books_data.find { |b| b[:isbn] == reservation_data[:isbn] }[:title]
      puts "#{member.name} reserved: #{book_title}"
    rescue StandardError => e
      puts "Reservation failed: #{e.message}"
    end
  end
  
  # Display final statistics
  puts "\n" + "="*50
  puts "SAMPLE DATA GENERATION COMPLETE"
  puts "="*50
  
  stats = library.statistics
  puts "Library Statistics:"
  puts "- Total Books: #{stats[:total_books]}"
  puts "- Total Members: #{stats[:total_members]}"
  puts "- Active Loans: #{stats[:active_loans]}"
  puts "- Active Reservations: #{stats[:active_reservations]}"
  
  puts "\nTop 3 Most Borrowed Books:"
  stats[:top_5_most_borrowed_books].first(3).each_with_index do |book_stat, index|
    puts "#{index + 1}. #{book_stat[:book].title} (#{book_stat[:borrow_count]} times)"
  end
  
  puts "\nMost Active Reader: #{stats[:most_active_reader]&.name || 'None'}"
  
  overdue_members = library.members_with_overdue_books
  if overdue_members.any?
    puts "\nMembers with Overdue Books:"
    overdue_members.each do |data|
      puts "- #{data[:member].name}: #{data[:total_late_fees]} rubles in late fees"
    end
  else
    puts "\nNo members currently have overdue books."
  end
  
  puts "\nData files created in: data/"
  puts "Log file created in: logs/"
  puts "\nUse the Library class to interact with this sample data."
end

# Run the generator if this file is executed directly
if __FILE__ == $0
  generate_sample_data
end