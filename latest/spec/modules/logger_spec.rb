require_relative '../../lib/modules/logger'
require 'fileutils'

RSpec.describe LibraryLogger do
  let(:test_log_file) { 'tmp/test_logs/test.log' }
  
  before do
    FileUtils.mkdir_p('tmp/test_logs')
    stub_const('LibraryLogger::LOG_FILE', test_log_file)
  end

  after do
    FileUtils.rm_f(test_log_file) if File.exist?(test_log_file)
  end

  describe '.log' do
    it 'creates log file if it does not exist' do
      LibraryLogger.log('INFO', 'Test message')
      expect(File.exist?(test_log_file)).to be true
    end

    it 'writes formatted log entry' do
      LibraryLogger.log('INFO', 'Test message')
      content = File.read(test_log_file)
      expect(content).to match(/\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] INFO: Test message/)
    end

    it 'includes context information' do
      LibraryLogger.log('INFO', 'Test message', { user: 'john', action: 'login' })
      content = File.read(test_log_file)
      expect(content).to include('user=john action=login')
    end

    it 'handles multiple log entries' do
      LibraryLogger.log('INFO', 'First message')
      LibraryLogger.log('ERROR', 'Second message')
      
      content = File.read(test_log_file)
      expect(content.lines.count).to eq(2)
      expect(content).to include('INFO: First message')
      expect(content).to include('ERROR: Second message')
    end
  end

  describe 'convenience methods' do
    it '.info logs with INFO level' do
      LibraryLogger.info('Info message')
      content = File.read(test_log_file)
      expect(content).to include('INFO: Info message')
    end

    it '.warn logs with WARN level' do
      LibraryLogger.warn('Warning message')
      content = File.read(test_log_file)
      expect(content).to include('WARN: Warning message')
    end

    it '.error logs with ERROR level' do
      LibraryLogger.error('Error message')
      content = File.read(test_log_file)
      expect(content).to include('ERROR: Error message')
    end

    it '.debug logs with DEBUG level' do
      LibraryLogger.debug('Debug message')
      content = File.read(test_log_file)
      expect(content).to include('DEBUG: Debug message')
    end
  end

  context 'when file operations fail' do
    before do
      stub_const('LibraryLogger::LOG_FILE', '/invalid/path/test.log')
    end

    it 'handles file write errors gracefully' do
      expect { LibraryLogger.log('INFO', 'Test message') }.not_to raise_error
    end

    it 'outputs warning to stderr on failure' do
      expect { LibraryLogger.log('INFO', 'Test message') }.to output(/Failed to write to log file/).to_stderr
    end
  end
end