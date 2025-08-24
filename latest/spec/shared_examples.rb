RSpec.shared_examples "a persistable object" do |klass|
  let(:object) { described_class.new(**valid_attributes) }
  
  it "converts to hash correctly" do
    hash = object.to_hash
    expect(hash).to be_a(Hash)
    expect(hash.keys).to include(*expected_hash_keys)
  end

  it "recreates from hash correctly" do
    hash = object.to_hash
    recreated = klass.from_hash(hash)
    
    expect(recreated).to eq(object)
    expect(recreated).to be_a(klass)
  end
end

RSpec.shared_examples "validates presence of" do |attribute|
  it "validates presence of #{attribute}" do
    invalid_attributes = valid_attributes.dup
    invalid_attributes[attribute] = nil
    
    expect {
      described_class.new(**invalid_attributes)
    }.to raise_error(ArgumentError)
  end

  it "validates #{attribute} is not empty string" do
    invalid_attributes = valid_attributes.dup
    invalid_attributes[attribute] = ""
    
    expect {
      described_class.new(**invalid_attributes)
    }.to raise_error(ArgumentError)
  end
end

RSpec.shared_examples "a loggable operation" do |operation, expected_log_level = 'INFO'|
  it "logs the #{operation} operation" do
    expect(LibraryLogger).to receive(expected_log_level.downcase.to_sym)
    subject
  end
end