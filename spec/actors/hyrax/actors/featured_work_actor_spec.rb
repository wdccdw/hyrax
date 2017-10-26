RSpec.describe Hyrax::Actors::FeaturedWorkActor do
  let(:ability) { ::Ability.new(depositor) }
  let(:env) { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:depositor) { create(:user) }
  let(:work) { create_for_repository(:work) }
  let(:attributes) { {} }
  let!(:feature) { FeaturedWork.create(work_id: work.id) }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  describe "#destroy" do
    it 'removes all the features' do
      expect { middleware.destroy(env) }.to change { FeaturedWork.where(work_id: work.id.to_s).count }.from(1).to(0)
    end
  end

  describe "#update" do
    context "of a public work" do
      let(:work) { create_for_repository(:work, :public) }

      it "does not modify the features" do
        expect { middleware.update(env) }.not_to change { FeaturedWork.where(work_id: work.id.to_s).count }
      end
    end

    context "of a private work" do
      it "removes the features" do
        expect { middleware.update(env) }.to change { FeaturedWork.where(work_id: work.id.to_s).count }.from(1).to(0)
      end
    end
  end
end
