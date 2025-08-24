require 'rspec'
require 'fileutils'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed

  config.before(:suite) do
    FileUtils.mkdir_p('tmp/test_data')
    FileUtils.mkdir_p('tmp/test_logs')
  end

  config.before(:each) do
    FileUtils.rm_rf(Dir.glob('tmp/test_data/*'))
    FileUtils.rm_rf(Dir.glob('tmp/test_logs/*'))
  end

  config.after(:suite) do
    FileUtils.rm_rf('tmp')
  end
end

def with_temp_files
  original_data_dir = DataStore::DATA_DIR
  original_log_file = LibraryLogger::LOG_FILE
  
  # Remove and redefine constants
  DataStore.send(:remove_const, :DATA_DIR)
  LibraryLogger.send(:remove_const, :LOG_FILE)
  DataStore.const_set(:DATA_DIR, 'tmp/test_data')
  LibraryLogger.const_set(:LOG_FILE, 'tmp/test_logs/test.log')
  
  yield
ensure
  # Restore original constants
  DataStore.send(:remove_const, :DATA_DIR)
  LibraryLogger.send(:remove_const, :LOG_FILE)
  DataStore.const_set(:DATA_DIR, original_data_dir)
  LibraryLogger.const_set(:LOG_FILE, original_log_file)
end