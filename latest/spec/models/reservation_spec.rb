require_relative '../../lib/models/reservation'
require_relative '../shared_examples'
require 'date'

RSpec.describe Reservation do
  let(:valid_attributes) do
    {
      book_isbn: '9780306406157',
      member_id: 'member-123'
    }
  end

  let(:expected_hash_keys) { [:id, :book_isbn, :member_id, :reservation_date, :expiration_date, :fulfilled] }

  describe 'initialization' do
    it 'creates a reservation with valid attributes' do
      reservation = Reservation.new(**valid_attributes)
      expect(reservation.book_isbn).to eq('9780306406157')
      expect(reservation.member_id).to eq('member-123')
      expect(reservation.id).to be_a(String)
      expect(reservation.reservation_date).to eq(Date.today)
      expect(reservation.expiration_date).to eq(Date.today + 3)
      expect(reservation.fulfilled).to be false
    end

    it 'accepts custom reservation date' do
      custom_date = Date.new(2023, 1, 1)
      reservation = Reservation.new(**valid_attributes.merge(reservation_date: custom_date))
      expect(reservation.reservation_date).to eq(custom_date)
      expect(reservation.expiration_date).to eq(custom_date + 3)
    end

    it 'accepts custom ID' do
      reservation = Reservation.new(**valid_attributes.merge(id: 'custom-id'))
      expect(reservation.id).to eq('custom-id')
    end

    it 'accepts string dates' do
      reservation = Reservation.new(**valid_attributes.merge(reservation_date: '2023-01-01'))
      expect(reservation.reservation_date).to eq(Date.new(2023, 1, 1))
    end

    it 'validates book_isbn presence' do
      expect {
        Reservation.new(**valid_attributes.merge(book_isbn: nil))
      }.to raise_error(ArgumentError, "Book ISBN cannot be empty")

      expect {
        Reservation.new(**valid_attributes.merge(book_isbn: ''))
      }.to raise_error(ArgumentError, "Book ISBN cannot be empty")
    end

    it 'validates member_id presence' do
      expect {
        Reservation.new(**valid_attributes.merge(member_id: nil))
      }.to raise_error(ArgumentError, "Member ID cannot be empty")

      expect {
        Reservation.new(**valid_attributes.merge(member_id: ''))
      }.to raise_error(ArgumentError, "Member ID cannot be empty")
    end

    it 'strips whitespace from string attributes' do
      reservation = Reservation.new(
        book_isbn: '  9780306406157  ',
        member_id: '  member-123  '
      )
      expect(reservation.book_isbn).to eq('9780306406157')
      expect(reservation.member_id).to eq('member-123')
    end
  end

  describe '#fulfill!' do
    let(:reservation) { Reservation.new(**valid_attributes) }

    it 'marks reservation as fulfilled' do
      reservation.fulfill!
      expect(reservation.fulfilled).to be true
    end

    it 'raises error if already fulfilled' do
      reservation.fulfill!
      expect { reservation.fulfill! }.to raise_error(StandardError, "Reservation already fulfilled")
    end
  end

  describe '#expired?' do
    it 'returns false for current reservation' do
      reservation = Reservation.new(**valid_attributes)
      expect(reservation.expired?).to be false
    end

    it 'returns true for expired reservation' do
      old_reservation = Reservation.new(**valid_attributes.merge(reservation_date: Date.today - 10))
      expect(old_reservation.expired?).to be true
    end

    it 'returns false for expired but fulfilled reservation' do
      old_reservation = Reservation.new(**valid_attributes.merge(reservation_date: Date.today - 10))
      old_reservation.fulfill!
      expect(old_reservation.expired?).to be false
    end

    it 'accepts custom current date' do
      reservation = Reservation.new(**valid_attributes.merge(reservation_date: Date.new(2023, 1, 1)))
      expect(reservation.expired?(Date.new(2023, 1, 10))).to be true
    end
  end

  describe '#active?' do
    it 'returns true for current unfulfilled reservation' do
      reservation = Reservation.new(**valid_attributes)
      expect(reservation.active?).to be true
    end

    it 'returns false for fulfilled reservation' do
      reservation = Reservation.new(**valid_attributes)
      reservation.fulfill!
      expect(reservation.active?).to be false
    end

    it 'returns false for expired reservation' do
      old_reservation = Reservation.new(**valid_attributes.merge(reservation_date: Date.today - 10))
      expect(old_reservation.active?).to be false
    end
  end

  describe '#days_until_expiration' do
    it 'calculates days until expiration' do
      reservation = Reservation.new(**valid_attributes)
      expect(reservation.days_until_expiration).to eq(3)
    end

    it 'returns 0 for expired reservations' do
      old_reservation = Reservation.new(**valid_attributes.merge(reservation_date: Date.today - 10))
      expect(old_reservation.days_until_expiration).to eq(0)
    end

    it 'returns 0 for fulfilled reservations' do
      reservation = Reservation.new(**valid_attributes)
      reservation.fulfill!
      expect(reservation.days_until_expiration).to eq(0)
    end

    it 'accepts custom current date' do
      reservation = Reservation.new(**valid_attributes.merge(reservation_date: Date.new(2023, 1, 1)))
      expect(reservation.days_until_expiration(Date.new(2023, 1, 2))).to eq(2)
    end
  end

  it_behaves_like "a persistable object", Reservation

  describe 'equality and hashing' do
    let(:reservation1) { Reservation.new(**valid_attributes.merge(id: 'same-id')) }
    let(:reservation2) { Reservation.new(**valid_attributes.merge(id: 'same-id')) }
    let(:different_reservation) { Reservation.new(**valid_attributes.merge(id: 'different-id')) }

    it 'treats reservations with same ID as equal' do
      expect(reservation1).to eq(reservation2)
      expect(reservation1.eql?(reservation2)).to be true
    end

    it 'treats reservations with different ID as not equal' do
      expect(reservation1).not_to eq(different_reservation)
    end

    it 'has consistent hash values for equal objects' do
      expect(reservation1.hash).to eq(reservation2.hash)
    end
  end

  describe '#to_s' do
    let(:reservation) { Reservation.new(**valid_attributes) }

    it 'returns readable string for active reservation' do
      expected = "Reservation #{reservation.id}: Book 9780306406157 for Member member-123, active (expires #{reservation.expiration_date})"
      expect(reservation.to_s).to eq(expected)
    end

    it 'returns readable string for fulfilled reservation' do
      reservation.fulfill!
      expected = "Reservation #{reservation.id}: Book 9780306406157 for Member member-123, fulfilled"
      expect(reservation.to_s).to eq(expected)
    end

    it 'returns readable string for expired reservation' do
      old_reservation = Reservation.new(**valid_attributes.merge(reservation_date: Date.today - 10))
      expected = "Reservation #{old_reservation.id}: Book 9780306406157 for Member member-123, expired"
      expect(old_reservation.to_s).to eq(expected)
    end
  end
end