require 'spec_helper'

RSpec.describe Reservation do
  let(:valid_attributes) do
    {
      id: 'RES_001',
      book_isbn: '9780132350884',
      member_id: 'MEM001',
      reservation_date: Time.new(2023, 6, 1, 12, 0, 0)
    }
  end

  subject { described_class.new(**valid_attributes) }

  it_behaves_like "a valid model"

  describe 'constants' do
    it 'has correct hold period' do
      expect(described_class::HOLD_PERIOD_DAYS).to eq(3)
    end
  end

  describe '#initialize' do
    context 'with valid attributes' do
      it 'creates a reservation with all attributes' do
        expect(subject.id).to eq('RES_001')
        expect(subject.book_isbn).to eq('9780132350884')
        expect(subject.member_id).to eq('MEM001')
        expect(subject.reservation_date).to eq(Time.new(2023, 6, 1, 12, 0, 0))
        expect(subject.expiration_date).to eq(Time.new(2023, 6, 4, 12, 0, 0))
        expect(subject.fulfilled).to be false
      end

      it 'uses current time as default reservation date' do
        reservation = described_class.new(**valid_attributes.except(:reservation_date))
        expect(reservation.reservation_date).to be_within(1).of(Time.now)
      end

      it 'accepts reservation date as string' do
        reservation = described_class.new(**valid_attributes.merge(reservation_date: '2023-06-01'))
        expect(reservation.reservation_date.year).to eq(2023)
        expect(reservation.reservation_date.month).to eq(6)
        expect(reservation.reservation_date.day).to eq(1)
      end

      it 'calculates expiration date correctly' do
        expected_expiration = valid_attributes[:reservation_date] + (3 * 24 * 60 * 60)
        expect(subject.expiration_date).to eq(expected_expiration)
      end
    end

    context 'with invalid attributes' do
      it 'raises error for empty ID' do
        expect {
          described_class.new(**valid_attributes.merge(id: ''))
        }.to raise_error(ArgumentError, "ID cannot be empty")
      end

      it 'raises error for nil ID' do
        expect {
          described_class.new(**valid_attributes.merge(id: nil))
        }.to raise_error(ArgumentError, "ID cannot be empty")
      end

      it 'raises error for empty book ISBN' do
        expect {
          described_class.new(**valid_attributes.merge(book_isbn: ''))
        }.to raise_error(ArgumentError, "Book ISBN cannot be empty")
      end

      it 'raises error for empty member ID' do
        expect {
          described_class.new(**valid_attributes.merge(member_id: ''))
        }.to raise_error(ArgumentError, "Member ID cannot be empty")
      end
    end
  end

  describe '#active?' do
    let(:current_date) { Time.new(2023, 6, 3, 12, 0, 0) }

    context 'when reservation is not fulfilled and not expired' do
      it 'returns true' do
        expect(subject.active?(current_date)).to be true
      end
    end

    context 'when reservation is fulfilled' do
      it 'returns false' do
        subject.fulfill
        expect(subject.active?(current_date)).to be false
      end
    end

    context 'when reservation is expired' do
      let(:expired_date) { Time.new(2023, 6, 5, 12, 0, 0) }
      
      it 'returns false' do
        expect(subject.active?(expired_date)).to be false
      end
    end

    it 'uses current time by default' do
      # This ensures the method works without explicitly passing time
      expect(subject.active?).to be_a(TrueClass).or be_a(FalseClass)
    end
  end

  describe '#expired?' do
    let(:current_date) { Time.new(2023, 6, 5, 12, 0, 0) }

    context 'when reservation is past expiration date and not fulfilled' do
      it 'returns true' do
        expect(subject.expired?(current_date)).to be true
      end
    end

    context 'when reservation is not past expiration date' do
      let(:early_date) { Time.new(2023, 6, 3, 12, 0, 0) }
      
      it 'returns false' do
        expect(subject.expired?(early_date)).to be false
      end
    end

    context 'when reservation is fulfilled' do
      it 'returns false even if past expiration' do
        subject.fulfill
        expect(subject.expired?(current_date)).to be false
      end
    end

    it 'uses current time by default' do
      # This ensures the method works without explicitly passing time
      expect(subject.expired?).to be_a(TrueClass).or be_a(FalseClass)
    end
  end

  describe '#fulfill' do
    it 'sets fulfilled to true' do
      expect { subject.fulfill }.to change { subject.fulfilled }.from(false).to(true)
    end

    it 'makes reservation inactive' do
      current_date = Time.new(2023, 6, 3, 12, 0, 0)
      expect(subject.active?(current_date)).to be true
      
      subject.fulfill
      expect(subject.active?(current_date)).to be false
    end
  end

  describe '#to_hash and .from_hash' do
    before { subject.fulfill }

    it 'serializes to hash correctly' do
      hash = subject.to_hash
      
      expect(hash).to include(
        id: 'RES_001',
        book_isbn: '9780132350884',
        member_id: 'MEM001',
        fulfilled: true
      )
      expect(hash[:reservation_date]).to be_a(String)
      expect(hash[:expiration_date]).to be_a(String)
    end

    it 'deserializes from hash correctly' do
      hash = subject.to_hash
      restored_reservation = described_class.from_hash(hash)
      
      expect(restored_reservation.id).to eq(subject.id)
      expect(restored_reservation.book_isbn).to eq(subject.book_isbn)
      expect(restored_reservation.member_id).to eq(subject.member_id)
      expect(restored_reservation.fulfilled).to eq(subject.fulfilled)
      expect(restored_reservation.reservation_date).to be_within(1).of(subject.reservation_date)
      expect(restored_reservation.expiration_date).to be_within(1).of(subject.expiration_date)
    end

    it 'handles string keys from JSON' do
      hash = {
        'id' => 'RES_001',
        'book_isbn' => '9780132350884',
        'member_id' => 'MEM001',
        'reservation_date' => '2023-06-01',
        'expiration_date' => '2023-06-04',
        'fulfilled' => false
      }
      
      restored_reservation = described_class.from_hash(hash)
      expect(restored_reservation.id).to eq('RES_001')
      expect(restored_reservation.fulfilled).to be false
    end

    it 'handles missing fulfilled field' do
      hash = {
        'id' => 'RES_001',
        'book_isbn' => '9780132350884',
        'member_id' => 'MEM001',
        'reservation_date' => '2023-06-01',
        'expiration_date' => '2023-06-04'
      }
      
      restored_reservation = described_class.from_hash(hash)
      expect(restored_reservation.fulfilled).to be false
    end
  end
end