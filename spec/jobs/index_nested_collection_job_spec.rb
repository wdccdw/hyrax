require 'spec_helper'

RSpec.describe IndexNestedCollectionJob do
  describe "#perform_later" do
    it "uses the configured reindexer" do
      expect(Hyrax.config.nested_relationship_reindexer).to receive(:call).with(id: 'test_id')
      IndexNestedCollectionJob.perform_later('test_id')
    end
  end
end
