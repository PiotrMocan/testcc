# Ruby Library Management System

Develop a library management system in Ruby with the following requirements:

## Functional Requirements

### Core Features:
- Add and remove books from the library catalog
- Register new library members
- Check out books to members (verify availability of copies)
- Return books with late fee calculation (10 rubles per day overdue)
- Search books by author, title, or genre
- Get list of members with overdue books
- Generate statistics: top 5 most borrowed books, most active reader
- Reserve books when all copies are checked out
- Track complete borrowing history for each member

### Business Rules:
- Each book can have multiple copies
- Members can borrow multiple books simultaneously
- Late fees accumulate daily after due date
- Reserved books should be held for 3 days
- Maximum borrowing period is 14 days

## Technical Requirements

### Implementation Requirements:
- Use modules for data validation (email format, ISBN format)
- Implement data persistence with JSON files
- Handle exceptions for critical operations
- Log all operations to a file with timestamps
- Follow SOLID principles and Ruby conventions
- Use appropriate design patterns where applicable

### Data Requirements:
- Books: ISBN, title, author, publication year, available copies, genre
- Members: ID, name, email, registration date, borrowing history
- Loans: book reference, member reference, checkout date, due date, return date
- Reservations: book reference, member reference, reservation date, expiration date

## Test Requirements

Write comprehensive test coverage using RSpec, including:

### Test Categories:
- Unit tests for all classes and modules
- Integration tests for main user scenarios
- Edge cases and error handling tests
- Mock file operations to avoid test dependencies

### Test Scenarios to Cover:
- Borrowing a book when copies are available
- Attempting to borrow when no copies available
- Returning books on time vs late
- Fee calculation for various overdue periods
- Search functionality with various inputs
- Reservation queue management
- Data persistence and recovery
- Validation of invalid inputs
- Concurrent operations handling

### Test Quality Expectations:
- Use RSpec best practices (let, before, context, describe)
- Implement shared examples for common behaviors
- Achieve >90% code coverage
- Include performance tests for search operations
- Test both happy paths and failure scenarios

## Expected Deliverables

1. Complete Ruby implementation with all features
2. RSpec test suite with full coverage
3. README with setup and usage instructions
4. Sample data files for testing

The code should be production-ready, maintainable, and demonstrate advanced Ruby programming skills.