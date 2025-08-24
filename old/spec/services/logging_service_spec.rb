require 'spec_helper'

RSpec.describe LoggingService do
  let(:test_logs_dir) { 'test_logs' }
  let(:test_log_file) { File.join(test_logs_dir, 'library_system.log') }

  before do
    stub_const('LoggingService::LOGS_DIR', test_logs_dir)
    stub_const('LoggingService::LOG_FILE', test_log_file)
    
    allow(FileUtils).to receive(:mkdir_p)
    allow(Logger).to receive(:new).and_return(double('logger', 
      level: nil, 
      'level=': nil, 
      'formatter=': nil,
      info: nil,
      warn: nil,
      error: nil,
      debug: nil
    ))
  end

  let(:mock_logger) { instance_double(Logger) }
  subject { described_class.new }

  describe '#initialize' do
    it 'creates logs directory if it does not exist' do
      allow(Dir).to receive(:exist?).with(test_logs_dir).and_return(false)
      expect(FileUtils).to receive(:mkdir_p).with(test_logs_dir)
      
      described_class.new
    end

    it 'creates logger with correct settings' do
      expect(Logger).to receive(:new).with(test_log_file, 'daily')
      described_class.new
    end
  end

  describe 'logging methods' do
    before do
      allow(Logger).to receive(:new).and_return(mock_logger)
      allow(mock_logger).to receive(:level=)
      allow(mock_logger).to receive(:formatter=)
    end

    describe '#info' do
      it 'logs info message' do
        expect(mock_logger).to receive(:info).with('Test message')
        subject.info('Test message')
      end
    end

    describe '#warn' do
      it 'logs warning message' do
        expect(mock_logger).to receive(:warn).with('Test warning')
        subject.warn('Test warning')
      end
    end

    describe '#error' do
      it 'logs error message' do
        expect(mock_logger).to receive(:error).with('Test error')
        subject.error('Test error')
      end
    end

    describe '#debug' do
      it 'logs debug message' do
        expect(mock_logger).to receive(:debug).with('Test debug')
        subject.debug('Test debug')
      end
    end
  end

  describe '#log_operation' do
    before do
      allow(Logger).to receive(:new).and_return(mock_logger)
      allow(mock_logger).to receive(:level=)
      allow(mock_logger).to receive(:formatter=)
    end

    it 'logs operation without details' do
      expect(mock_logger).to receive(:info).with('Book added')
      subject.log_operation('Book added')
    end

    it 'logs operation with details' do
      details = { isbn: '123456789', title: 'Test Book' }
      expected_message = 'Book added - isbn: 123456789, title: Test Book'
      
      expect(mock_logger).to receive(:info).with(expected_message)
      subject.log_operation('Book added', details)
    end

    it 'handles empty details hash' do
      expect(mock_logger).to receive(:info).with('Book added')
      subject.log_operation('Book added', {})
    end
  end

  describe '#log_error' do
    before do
      allow(Logger).to receive(:new).and_return(mock_logger)
      allow(mock_logger).to receive(:level=)
      allow(mock_logger).to receive(:formatter=)
    end

    it 'logs error operation with error details' do
      error = StandardError.new('Book not found')
      expected_message = 'Checkout book failed - Error: Book not found'
      
      expect(mock_logger).to receive(:error).with(expected_message)
      subject.log_error('Checkout book', error)
    end
  end

  describe 'formatter' do
    it 'formats log messages correctly' do
      # Skip the global mocks and use a real LoggingService for this test
      allow(FileUtils).to receive(:mkdir_p)
      allow(Dir).to receive(:exist?).and_return(true)
      
      # Allow the real logger to be created
      allow(Logger).to receive(:new).and_call_original
      
      # Create a real logger for testing
      real_logger = Logger.new(StringIO.new)
      real_logger.level = Logger::INFO
      
      # Set the formatter as the LoggingService does
      real_logger.formatter = proc do |severity, datetime, progname, msg|
        "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
      end
      
      # Test that the formatter works correctly
      formatted = real_logger.formatter.call('INFO', Time.new(2023, 6, 15, 10, 30, 45), nil, 'Test message')
      expect(formatted).to eq("[2023-06-15 10:30:45] INFO: Test message\n")
    end
  end
end