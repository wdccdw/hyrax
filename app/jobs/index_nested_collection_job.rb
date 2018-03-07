class IndexNestedCollectionJob < Hyrax::ApplicationJob
  def perform(id)
    Hyrax.config.nested_relationship_reindexer.call(id: id)
  end
end
