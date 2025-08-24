require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  minimum_coverage 90
end

require_relative '../lib/library_system'
require_relative '../lib/models/book'
require_relative '../lib/models/member'
require_relative '../lib/models/loan'
require_relative '../lib/models/reservation'
require_relative '../lib/modules/validators'
require_relative '../lib/services/persistence_service'
require_relative '../lib/services/logging_service'

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

  config.before(:each) do
    allow(File).to receive(:write).and_call_original
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:exist?).and_call_original
    allow(Dir).to receive(:exist?).and_call_original
    allow(FileUtils).to receive(:mkdir_p).and_call_original
  end
end

RSpec.shared_examples "a valid model" do
  it "responds to to_hash" do
    expect(subject).to respond_to(:to_hash)
  end

  it "responds to from_hash" do
    expect(described_class).to respond_to(:from_hash)
  end

  it "can be serialized and deserialized" do
    hash = subject.to_hash
    restored = described_class.from_hash(hash)
    
    expect(restored.to_hash).to eq(hash)
  end
end