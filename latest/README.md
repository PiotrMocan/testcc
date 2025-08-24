# Ruby Library Management System

A comprehensive library management system built in Ruby with full functionality for managing books, members, loans, and reservations. The system includes late fee calculations, search capabilities, and detailed reporting features.

## Features

### Core Functionality
- **Book Management**: Add, remove, and search books with multiple copies support
- **Member Management**: Register members with email validation and borrowing history tracking
- **Loan System**: Check out and return books with automatic due date calculation (14-day borrowing period)
- **Reservation Queue**: Reserve books when all copies are checked out (3-day hold period)
- **Late Fee Calculation**: Automatic calculation at 10 rubles per day overdue
- **Search Engine**: Search books by title, author, or genre
- **Statistics & Reports**: Top borrowed books, most active readers, overdue books tracking

### Technical Features
- **Data Validation**: Email format and ISBN validation (both ISBN-10 and ISBN-13)
- **JSON Persistence**: All data stored in JSON files for persistence
- **Comprehensive Logging**: All operations logged with timestamps
- **Exception Handling**: Robust error handling for critical operations
- **SOLID Principles**: Clean, maintainable code following Ruby conventions

## Installation & Setup

### Prerequisites
- Ruby 3.0 or later
- Bundler gem

### Installation
1. Clone or download the project
2. Navigate to the project directory
3. Install dependencies:
   ```bash
   bundle install
   ```

### Directory Structure
```
├── lib/
│   ├── models/          # Core domain models
│   ├── modules/         # Validation and utility modules
│   ├── services/        # Data persistence layer
│   └── library.rb       # Main library class
├── spec/                # RSpec test suite
├── data/                # JSON data files (created automatically)
├── logs/                # Log files (created automatically)
└── sample_data/         # Sample data for testing
```

## Usage Examples

### Basic Operations

```ruby
require_relative 'lib/library'

# Create a new library instance
library = Library.new

# Add books to the catalog
library.add_book(
  isbn: '978-0-306-40615-7',
  title: 'The Great Gatsby',
  author: 'F. Scott Fitzgerald',
  publication_year: 1925,
  total_copies: 3,
  genre: 'Fiction'
)

# Register a new member
member = library.register_member(
  name: 'John Doe',
  email: 'john.doe@example.com'
)

# Check out a book
loan = library.checkout_book(
  isbn: '978-0-306-40615-7',
  member_id: member.id
)

# Return a book
returned_loan = library.return_book(
  isbn: '978-0-306-40615-7',
  member_id: member.id
)

# Search for books
results = library.search_books(query: 'Gatsby')

# Get library statistics
stats = library.statistics
puts "Total books: #{stats[:total_books]}"
puts "Active loans: #{stats[:active_loans]}"
```

### Advanced Features

```ruby
# Reserve a book when no copies available
reservation = library.reserve_book(
  isbn: '978-0-306-40615-7',
  member_id: member.id
)

# Get members with overdue books
overdue_members = library.members_with_overdue_books
overdue_members.each do |data|
  puts "#{data[:member].name} owes #{data[:total_late_fees]} rubles"
end

# Get member borrowing history
history = library.get_member_borrowing_history(member.id)
puts "Total books borrowed: #{history[:total_books_borrowed]}"
puts "Current loans: #{history[:current_loans_count]}"

# Cleanup expired reservations
expired_count = library.cleanup_expired_reservations
puts "Removed #{expired_count} expired reservations"
```

## Testing

The project includes comprehensive RSpec tests with >90% code coverage.

### Run All Tests
```bash
bundle exec rspec
```

### Run Specific Test Categories
```bash
# Unit tests for models
bundle exec rspec spec/models/

# Unit tests for modules
bundle exec rspec spec/modules/

# Integration tests
bundle exec rspec spec/library_spec.rb

# Service layer tests
bundle exec rspec spec/services/
```

### Test Coverage
The test suite includes:
- Unit tests for all classes and modules
- Integration tests for main user scenarios
- Edge cases and error handling tests
- Mocked file operations to avoid test dependencies
- Shared examples for common behaviors
- Performance considerations for search operations

## Data Models

### Book
- **ISBN**: Unique identifier (validated for ISBN-10/ISBN-13 format)
- **Title**: Book title
- **Author**: Book author
- **Publication Year**: Year of publication
- **Total Copies**: Total copies owned by library
- **Available Copies**: Currently available copies
- **Genre**: Book genre (optional)

### Member
- **ID**: Unique member identifier (UUID)
- **Name**: Member's full name
- **Email**: Email address (validated format)
- **Registration Date**: Date of membership registration
- **Borrowing History**: Complete history of all loans

### Loan
- **ID**: Unique loan identifier (UUID)
- **Book ISBN**: Reference to borrowed book
- **Member ID**: Reference to borrowing member
- **Checkout Date**: Date book was borrowed
- **Due Date**: Date book is due (checkout date + 14 days)
- **Return Date**: Date book was returned (null if active)
- **Late Fee**: Calculated late fee (10 rubles per day overdue)

### Reservation
- **ID**: Unique reservation identifier (UUID)
- **Book ISBN**: Reference to reserved book
- **Member ID**: Reference to reserving member
- **Reservation Date**: Date reservation was made
- **Expiration Date**: Date reservation expires (reservation date + 3 days)
- **Fulfilled**: Whether reservation has been fulfilled

## Business Rules

1. **Borrowing Period**: Maximum 14 days per loan
2. **Late Fees**: 10 rubles per day after due date
3. **Reservation Hold**: 3 days to pick up reserved books
4. **Multiple Copies**: Each book can have multiple copies
5. **Concurrent Borrowing**: Members can borrow multiple books simultaneously
6. **Validation**: Email format and ISBN format validation required
7. **Active Loan Restriction**: Cannot remove books with active loans

## Logging

All operations are logged to `logs/library.log` with:
- Timestamp in YYYY-MM-DD HH:MM:SS format
- Log level (INFO, WARN, ERROR, DEBUG)
- Operation description
- Contextual information (IDs, names, etc.)

Example log entry:
```
[2023-12-01 14:30:15] INFO: Book checked out | isbn=978-0-306-40615-7 member_id=abc-123 loan_id=def-456
```

## Error Handling

The system includes comprehensive error handling for:
- Invalid input validation (ISBN format, email format)
- Business rule violations (borrowing unavailable books)
- Data persistence failures (file I/O errors)
- Concurrent operations (checkout/return conflicts)

## Performance Considerations

- **Search Operations**: Implemented with efficient string matching
- **Data Loading**: Lazy loading from JSON files
- **Memory Management**: Efficient data structure usage
- **File I/O**: Batched writes to minimize disk operations

## Sample Data

The system includes sample data files for testing and demonstration:
- Sample books from various genres
- Test members with different borrowing patterns
- Example loans and reservations
- Realistic late fee scenarios

## Contributing

1. Follow Ruby style conventions
2. Maintain test coverage above 90%
3. Add logging for all new operations
4. Update documentation for new features
5. Validate all inputs and handle errors gracefully

## License

This project is created as a technical demonstration of Ruby programming skills and library management system design.