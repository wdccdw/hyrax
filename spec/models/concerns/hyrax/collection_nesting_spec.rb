RSpec.describe Hyrax::CollectionNesting do
  describe 'including this module' do
    let(:klass) do
      Class.new do
        extend ActiveModel::Callbacks
        include ActiveModel::Validations::Callbacks
        # Because we need these declared before we include the Hyrax::CollectionNesting
        define_model_callbacks :destroy, only: :after

        def destroy
          true
        end

        def update_index
          true
        end

        include Hyrax::CollectionNesting

        attr_accessor :id
      end
    end

    let(:user) { create(:user) }
    let(:collection) { create(:collection, collection_type_settings: [:nestable]) }
    subject { klass.new.tap { |obj| obj.id = collection.id } }

    it { is_expected.to callback(:update_nested_collection_relationship_indices).after(:update_index) }
    it { is_expected.to callback(:update_child_nested_collection_relationship_indices).after(:destroy) }
    it { is_expected.to respond_to(:update_nested_collection_relationship_indices) }
    it { is_expected.to respond_to(:update_child_nested_collection_relationship_indices) }
    it { is_expected.to respond_to(:use_nested_reindexing?) }

    describe '#update_nested_collection_relationship_indices' do
      it 'will enqueue a job to index the collection later' do
        expect(IndexNestedCollectionJob).to receive(:perform_later).with(collection.id)
        subject.update_nested_collection_relationship_indices
      end
    end

    context 'with children' do
      let(:child_collections) {[
        create(:collection, collection_type_settings: [:nestable]),
        create(:collection, collection_type_settings: [:nestable])
      ]}

      before do
        child_collections.each do |child|
          Hyrax::Collections::NestedCollectionPersistenceService.persist_nested_collection_for(parent: collection, child: child)
        end
      end

      describe '#update_child_nested_collection_relationship_indices' do
        it 'will enqueue a job to reindex all child collections later' do
          child_collections.each do |child|
            expect(IndexNestedCollectionJob).to receive(:perform_later).with(child.id)
          end
          subject.update_child_nested_collection_relationship_indices
        end
      end

      describe '#find_children_of' do
        it 'will return an array containing the child collection ids' do
          expect(subject.find_children_of(destroyed_id: collection.id).map(&:id)).to match_array(child_collections.map(&:id))
        end
      end
    end
  end
end
