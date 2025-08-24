#!/usr/bin/env ruby
require_relative 'lib/library_system'

puts "Creating sample data for Library Management System..."

library = LibrarySystem.new

begin
  # Add sample books
  puts "Adding sample books..."
  
  sample_books = [
    {
      isbn: '9780132350884',
      title: 'Clean Code: A Handbook of Agile Software Craftsmanship',
      author: 'Robert C. Martin',
      publication_year: 2008,
      total_copies: 5,
      genre: 'Programming'
    },
    {
      isbn: '9780321146533',
      title: 'Test-Driven Development: By Example',
      author: 'Kent Beck',
      publication_year: 2002,
      total_copies: 3,
      genre: 'Programming'
    },
    {
      isbn: '9780201616224',
      title: 'The Pragmatic Programmer',
      author: 'David Thomas, Andrew Hunt',
      publication_year: 1999,
      total_copies: 4,
      genre: 'Programming'
    },
    {
      isbn: '9780134685991',
      title: 'Effective Java',
      author: 'Joshua Bloch',
      publication_year: 2017,
      total_copies: 2,
      genre: 'Programming'
    },
    {
      isbn: '9780596517748',
      title: 'JavaScript: The Good Parts',
      author: 'Douglas Crockford',
      publication_year: 2008,
      total_copies: 3,
      genre: 'Programming'
    },
    {
      isbn: '9780061120084',
      title: 'To Kill a Mockingbird',
      author: 'Harper Lee',
      publication_year: 1960,
      total_copies: 4,
      genre: 'Fiction'
    },
    {
      isbn: '9780143127741',
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      publication_year: 1925,
      total_copies: 3,
      genre: 'Fiction'
    },
    {
      isbn: '9780141439518',
      title: 'Pride and Prejudice',
      author: 'Jane Austen',
      publication_year: 1813,
      total_copies: 2,
      genre: 'Fiction'
    },
    {
      isbn: '9780375760891',
      title: 'A Brief History of Time',
      author: 'Stephen Hawking',
      publication_year: 1988,
      total_copies: 2,
      genre: 'Science'
    },
    {
      isbn: '9780307887436',
      title: 'Thinking, Fast and Slow',
      author: 'Daniel Kahneman',
      publication_year: 2011,
      total_copies: 3,
      genre: 'Psychology'
    }
  ]

  sample_books.each do |book_data|
    library.add_book(**book_data)
    puts "  ✓ Added: #{book_data[:title]}"
  end

  # Register sample members
  puts "\nRegistering sample members..."
  
  sample_members = [
    {
      id: 'MEM001',
      name: 'Alice Johnson',
      email: 'alice.johnson@email.com'
    },
    {
      id: 'MEM002',
      name: 'Bob Smith',
      email: 'bob.smith@email.com'
    },
    {
      id: 'MEM003',
      name: 'Carol Davis',
      email: 'carol.davis@email.com'
    },
    {
      id: 'MEM004',
      name: 'David Wilson',
      email: 'david.wilson@email.com'
    },
    {
      id: 'MEM005',
      name: 'Eve Brown',
      email: 'eve.brown@email.com'
    },
    {
      id: 'MEM006',
      name: 'Frank Miller',
      email: 'frank.miller@email.com'
    }
  ]

  sample_members.each do |member_data|
    library.register_member(**member_data)
    puts "  ✓ Registered: #{member_data[:name]}"
  end

  # Create some sample loans (current checkouts)
  puts "\nCreating sample loans..."
  
  sample_loans = [
    { member_id: 'MEM001', isbn: '9780132350884' },
    { member_id: 'MEM002', isbn: '9780321146533' },
    { member_id: 'MEM003', isbn: '9780201616224' },
    { member_id: 'MEM004', isbn: '9780061120084' },
    { member_id: 'MEM005', isbn: '9780375760891' }
  ]

  sample_loans.each do |loan_data|
    loan = library.checkout_book(**loan_data)
    member_name = sample_members.find { |m| m[:id] == loan_data[:member_id] }[:name]
    book_title = sample_books.find { |b| b[:isbn] == loan_data[:isbn] }[:title]
    puts "  ✓ #{member_name} checked out: #{book_title}"
  end

  # Create some sample reservations
  puts "\nCreating sample reservations..."
  
  # First, make some books unavailable by checking out all copies
  library.checkout_book(member_id: 'MEM006', isbn: '9780134685991') # 2nd copy
  library.checkout_book(member_id: 'MEM001', isbn: '9780134685991') # Last copy - now unavailable
  
  # Now create reservations
  sample_reservations = [
    { member_id: 'MEM002', isbn: '9780134685991' },
    { member_id: 'MEM003', isbn: '9780134685991' }
  ]

  sample_reservations.each do |reservation_data|
    reservation = library.reserve_book(**reservation_data)
    member_name = sample_members.find { |m| m[:id] == reservation_data[:member_id] }[:name]
    book_title = sample_books.find { |b| b[:isbn] == reservation_data[:isbn] }[:title]
    puts "  ✓ #{member_name} reserved: #{book_title}"
  end

  # Create some returned books with history (simulate past activity)
  puts "\nSimulating some returned books for history..."
  
  # Temporarily create and return some loans for history
  past_checkout_date = Time.now - (30 * 24 * 60 * 60) # 30 days ago
  past_return_date = Time.now - (20 * 24 * 60 * 60)   # 20 days ago (returned on time)
  
  # We'll manually add to member history since we can't easily backdate actual loans
  member = library.instance_variable_get(:@members).find { |m| m.id == 'MEM001' }
  member.add_to_history({
    book_isbn: '9780596517748',
    checkout_date: past_checkout_date,
    due_date: past_checkout_date + (14 * 24 * 60 * 60),
    return_date: past_return_date
  })

  member = library.instance_variable_get(:@members).find { |m| m.id == 'MEM002' }
  member.add_to_history({
    book_isbn: '9780143127741',
    checkout_date: past_checkout_date + (5 * 24 * 60 * 60),
    due_date: past_checkout_date + (19 * 24 * 60 * 60),
    return_date: past_checkout_date + (25 * 24 * 60 * 60) # 6 days late
  })

  # Save the updated member data
  library.instance_variable_get(:@persistence).save_members(library.instance_variable_get(:@members))

  puts "  ✓ Added borrowing history for demonstration"

  # Display summary statistics
  puts "\n" + "="*50
  puts "LIBRARY SYSTEM SAMPLE DATA CREATED SUCCESSFULLY"
  puts "="*50
  
  stats = library.get_statistics
  puts "\nLibrary Statistics:"
  puts "  📚 Total Books: #{stats[:total_books]}"
  puts "  👥 Total Members: #{stats[:total_members]}"
  puts "  📖 Active Loans: #{stats[:active_loans]}"
  puts "  📝 Active Reservations: #{stats[:active_reservations]}"
  
  puts "\nTop Borrowed Books:"
  stats[:top_borrowed_books].first(3).each_with_index do |book_stat, index|
    puts "  #{index + 1}. #{book_stat[:book].title} (#{book_stat[:borrow_count]} times)"
  end
  
  if stats[:most_active_member][:member]
    puts "\nMost Active Member:"
    puts "  🏆 #{stats[:most_active_member][:member].name} (#{stats[:most_active_member][:borrow_count]} books)"
  end

  overdue_members = library.get_overdue_members
  if overdue_members.any?
    puts "\nOverdue Information:"
    overdue_members.each do |overdue_info|
      puts "  ⚠️  #{overdue_info[:member].name}: #{overdue_info[:total_late_fee]} rubles in fees"
    end
  else
    puts "\n✅ No overdue books currently"
  end

  puts "\nSample data files created in:"
  puts "  📁 data/books.json"
  puts "  📁 data/members.json" 
  puts "  📁 data/loans.json"
  puts "  📁 data/reservations.json"
  puts "  📁 logs/library_system.log"
  
  puts "\nYou can now:"
  puts "  • Run tests: bundle exec rspec"
  puts "  • Explore the system with the sample data"
  puts "  • Check log files for operation history"

rescue => e
  puts "\n❌ Error creating sample data: #{e.message}"
  puts "Stack trace:"
  puts e.backtrace.first(5).map { |line| "  #{line}" }
end