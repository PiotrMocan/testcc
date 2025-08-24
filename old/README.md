# Ruby Library Management System

A comprehensive library management system built in Ruby that provides full functionality for managing books, members, loans, and reservations with persistent data storage and comprehensive logging.

## Features

### Core Library Operations
- **Book Management**: Add/remove books, track multiple copies, manage availability
- **Member Management**: Register members with email validation, track borrowing history
- **Loan System**: Check out/return books with automatic due date calculation
- **Reservation System**: Reserve books when unavailable, automatic expiration handling
- **Late Fee Calculation**: 10 rubles per day for overdue books
- **Search Functionality**: Search books by title, author, genre, or ISBN

### Advanced Features
- **Statistics**: Top 5 most borrowed books, most active member
- **Overdue Tracking**: List members with overdue books and accumulated fees
- **Data Persistence**: JSON file storage with backup functionality
- **Comprehensive Logging**: All operations logged with timestamps
- **Input Validation**: Email format and ISBN validation
- **Error Handling**: Robust exception handling with detailed error messages

## Installation

### Prerequisites
- Ruby 2.7.0 or higher
- Bundler gem

### Setup
1. Clone or download the project files
2. Navigate to the project directory
3. Install dependencies:
   ```bash
   bundle install
   ```

## Usage

### Basic Setup
```ruby
require_relative 'lib/library_system'

# Initialize the library system
library = LibrarySystem.new
```

### Book Management
```ruby
# Add a new book
library.add_book(
  isbn: '9780132350884',
  title: 'Clean Code',
  author: 'Robert C. Martin',
  publication_year: 2008,
  total_copies: 3,
  genre: 'Programming'
)

# Add more copies of existing book
library.add_book(
  isbn: '9780132350884',
  title: 'Clean Code',
  author: 'Robert C. Martin',
  publication_year: 2008,
  total_copies: 2,  # Adds 2 more copies
  genre: 'Programming'
)

# Remove a book (only if no active loans)
library.remove_book('9780132350884')

# Search books
results = library.search_books(query: 'clean code', field: :title)
results = library.search_books(query: 'martin', field: :author)
results = library.search_books(query: 'programming', field: :genre)
results = library.search_books(query: 'robert martin') # searches all fields
```

### Member Management
```ruby
# Register a new member
library.register_member(
  id: 'MEM001',
  name: 'John Doe',
  email: 'john.doe@example.com'
)

# Get member borrowing history
history = library.get_member_history('MEM001')
```

### Loan Operations
```ruby
# Check out a book
loan = library.checkout_book(member_id: 'MEM001', isbn: '9780132350884')

# Return a book
result = library.return_book(member_id: 'MEM001', isbn: '9780132350884')
puts "Late fee: #{result[:late_fee]} rubles"
puts "Days overdue: #{result[:days_overdue]}"

# Return with specific date
result = library.return_book(
  member_id: 'MEM001', 
  isbn: '9780132350884',
  return_date: Time.new(2023, 6, 15)
)
```

### Reservations
```ruby
# Reserve a book (when not available)
reservation = library.reserve_book(member_id: 'MEM001', isbn: '9780132350884')

# Clean up expired reservations
expired_count = library.cleanup_expired_reservations
```

### Reports and Statistics
```ruby
# Get overdue members
overdue_members = library.get_overdue_members
overdue_members.each do |info|
  puts "Member: #{info[:member].name}"
  puts "Total late fee: #{info[:total_late_fee]} rubles"
  puts "Overdue books: #{info[:overdue_books].size}"
end

# Get library statistics
stats = library.get_statistics
puts "Total books: #{stats[:total_books]}"
puts "Total members: #{stats[:total_members]}"
puts "Active loans: #{stats[:active_loans]}"
puts "Most active member: #{stats[:most_active_member][:member]&.name}"

# Top borrowed books
stats[:top_borrowed_books].each_with_index do |book_stat, index|
  puts "#{index + 1}. #{book_stat[:book].title} (#{book_stat[:borrow_count]} times)"
end
```

## Business Rules

### Borrowing Rules
- Maximum borrowing period: **14 days**
- Late fee: **10 rubles per day** after due date
- Members can borrow multiple books simultaneously
- Books must be available to checkout

### Reservation Rules
- Reservations are created when all copies are checked out
- Reservation hold period: **3 days**
- Expired reservations are automatically cleaned up
- Members cannot have multiple reservations for the same book

### Validation Rules
- **ISBN**: Must be valid ISBN-10 or ISBN-13 format
- **Email**: Must be valid email format
- **Book Data**: Title, author, and genre cannot be empty
- **Publication Year**: Must be between 1800 and current year
- **Copies**: Must be positive number

## File Structure

```
├── lib/
│   ├── library_system.rb          # Main system class
│   ├── models/
│   │   ├── book.rb                # Book model
│   │   ├── member.rb              # Member model
│   │   ├── loan.rb                # Loan model
│   │   └── reservation.rb         # Reservation model
│   ├── modules/
│   │   └── validators.rb          # Validation utilities
│   └── services/
│       ├── persistence_service.rb # JSON data storage
│       └── logging_service.rb     # Logging functionality
├── spec/                          # RSpec test suite
├── data/                          # JSON data files
├── logs/                          # Log files
└── README.md                      # This file
```

## Testing

Run the complete test suite:
```bash
bundle exec rspec
```

Run specific test files:
```bash
bundle exec rspec spec/models/book_spec.rb
bundle exec rspec spec/library_system_spec.rb
```

Run tests with coverage:
```bash
bundle exec rspec --format documentation
```

### Test Coverage
The test suite includes:
- **Unit tests** for all models and modules
- **Integration tests** for the main LibrarySystem class
- **Edge case testing** for error conditions
- **Mock testing** for file operations
- **Shared examples** for common model behaviors
- **Performance considerations** for search operations

## Data Persistence

### Storage Format
All data is stored in JSON format in the `data/` directory:
- `books.json` - Book catalog
- `members.json` - Member information
- `loans.json` - Loan records
- `reservations.json` - Reservation records

### Backup
```ruby
# Create backup of all data
backup_dir = library.instance_variable_get(:@persistence).backup_data
puts "Data backed up to: #{backup_dir}"
```

## Logging

All operations are logged with timestamps to `logs/library_system.log`:
- Book additions/removals
- Member registrations
- Loan transactions
- Reservation activities
- Error conditions
- System operations

Log entries include operation details and relevant data for audit purposes.

## Error Handling

The system provides comprehensive error handling:
- **Validation errors** for invalid input data
- **Business rule violations** (e.g., removing books with active loans)
- **Not found errors** for missing books/members
- **File system errors** for data persistence issues
- **Detailed error messages** for troubleshooting

## Example Usage Script

```ruby
#!/usr/bin/env ruby
require_relative 'lib/library_system'

# Initialize system
library = LibrarySystem.new

# Add some books
library.add_book(
  isbn: '9780132350884',
  title: 'Clean Code',
  author: 'Robert C. Martin',
  publication_year: 2008,
  total_copies: 3,
  genre: 'Programming'
)

library.add_book(
  isbn: '9780321146533',
  title: 'Test Driven Development',
  author: 'Kent Beck',
  publication_year: 2002,
  total_copies: 2,
  genre: 'Programming'
)

# Register members
library.register_member(
  id: 'MEM001',
  name: 'Alice Johnson',
  email: 'alice@example.com'
)

library.register_member(
  id: 'MEM002',
  name: 'Bob Smith',
  email: 'bob@example.com'
)

# Check out books
loan1 = library.checkout_book(member_id: 'MEM001', isbn: '9780132350884')
loan2 = library.checkout_book(member_id: 'MEM002', isbn: '9780321146533')

# Return a book late
late_return = library.return_book(
  member_id: 'MEM001',
  isbn: '9780132350884',
  return_date: loan1.due_date + (5 * 24 * 60 * 60) # 5 days late
)

puts "Late fee charged: #{late_return[:late_fee]} rubles"

# Show statistics
stats = library.get_statistics
puts "Library has #{stats[:total_books]} books and #{stats[:total_members]} members"
puts "Currently #{stats[:active_loans]} books are checked out"
```

## Design Patterns Used

- **Single Responsibility Principle**: Each class has a clear, single purpose
- **Dependency Injection**: Services are injected into the main system
- **Strategy Pattern**: Different validation strategies for ISBN formats
- **Template Method**: Consistent serialization pattern across models
- **Observer Pattern**: Logging service observes all operations
- **Factory Pattern**: ID generation for loans and reservations

## Performance Considerations

- **In-memory operations** for fast searching and filtering
- **Lazy loading** of data only when needed
- **Efficient JSON serialization** with pretty formatting for debugging
- **Daily log rotation** to prevent large log files
- **Indexed searching** by ISBN and member ID for O(n) performance

The system is designed to handle hundreds of books and members efficiently while maintaining data integrity and comprehensive audit trails.