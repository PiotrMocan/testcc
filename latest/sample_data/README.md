# Sample Data for Library Management System

This directory contains utilities for generating realistic sample data to test and demonstrate the Library Management System.

## Quick Start

Generate sample data by running:

```bash
cd sample_data
ruby generate_sample_data.rb
```

This will create:
- 10 books across various genres (Fiction, Fantasy, Mystery, etc.)
- 8 library members with realistic names and emails
- Active loans (5 books currently checked out)
- Returned loans with realistic patterns (some on time, some overdue)
- Book reservations for popular titles
- Complete borrowing history for all members

## Generated Data Overview

### Sample Books
- **The Handmaid's Tale** by Margaret Atwood (Dystopian Fiction)
- **1984** by George Orwell (Dystopian Fiction)
- **Brave New World** by Aldous Huxley (Science Fiction)
- **Pride and Prejudice** by Jane Austen (Romance)
- **The Kite Runner** by Khaled Hosseini (Historical Fiction)
- **Harry Potter and the Sorcerer's Stone** by J.K. Rowling (Fantasy)
- **The Lord of the Rings** by J.R.R. Tolkien (Fantasy)
- **The Alchemist** by Paulo Coelho (Philosophy)
- **The Catcher in the Rye** by J.D. Salinger (Coming of Age)
- **Gone Girl** by Gillian Flynn (Mystery Thriller)

### Sample Members
- Alice Johnson (alice.johnson@email.com)
- Bob Smith (bob.smith@email.com)
- Carol Davis (carol.davis@email.com)
- David Wilson (david.wilson@email.com)
- Emma Brown (emma.brown@email.com)
- Frank Miller (frank.miller@email.com)
- Grace Lee (grace.lee@email.com)
- Henry Taylor (henry.taylor@email.com)

### Realistic Scenarios

The sample data includes:

1. **Active Borrowers**: Several members with books currently checked out
2. **Overdue Situations**: Some members with overdue books and accumulated late fees
3. **Popular Books**: Books with multiple copies and high demand
4. **Reservation Queue**: Books reserved by members waiting for returns
5. **Varied Borrowing Patterns**: Different reading habits and return behaviors

## Using the Sample Data

After generation, you can interact with the sample data:

```ruby
require_relative '../lib/library'

# Load existing data (automatically loads from JSON files)
library = Library.new

# Search for popular books
results = library.search_books(query: 'Harry Potter')
puts "Found: #{results.first.title} - Available: #{results.first.available_copies}"

# Check library statistics
stats = library.statistics
puts "Most borrowed book: #{stats[:top_5_most_borrowed_books].first[:book].title}"
puts "Most active reader: #{stats[:most_active_reader].name}"

# View overdue books
overdue = library.members_with_overdue_books
overdue.each do |data|
  puts "#{data[:member].name} owes #{data[:total_late_fees]} rubles"
end
```

## Customization

You can modify `generate_sample_data.rb` to:
- Add more books or members
- Create different borrowing patterns
- Simulate specific scenarios (all books checked out, many overdue, etc.)
- Generate data for performance testing

## Files Created

After running the generator, you'll find:
- `data/books.json` - All book records
- `data/members.json` - All member records  
- `data/loans.json` - All loan records (active and completed)
- `data/reservations.json` - All reservation records
- `logs/library.log` - Complete operation log

## Reset Data

To start fresh:
1. Delete the `data/` directory contents
2. Delete the `logs/` directory contents  
3. Re-run the generator

The system will automatically recreate the directory structure and files.

## Integration with Tests

The sample data can be used for manual testing and integration testing:

```bash
# Generate sample data
ruby sample_data/generate_sample_data.rb

# Run integration tests with sample data
bundle exec rspec spec/integration/ --tag sample_data
```