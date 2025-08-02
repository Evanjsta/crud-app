defmodule Stepvo.Conversation.Comment do
  use Ash.Resource,
    domain: Stepvo.Conversation,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("comments")
    repo(Stepvo.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :content, :string do
      allow_nil?(false)
      constraints(min_length: 2, max_length: 350)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to :user, Stepvo.Conversation.User do
      destination_attribute(:id)
      attribute_type(:uuid)
      allow_nil?(false)
    end

    belongs_to :parent_comment, Stepvo.Conversation.Comment do
      destination_attribute(:id)
      source_attribute(:parent_comment_id)
      attribute_type(:uuid)
      allow_nil?(true)
    end

    has_many :child_comments, Stepvo.Conversation.Comment do
      source_attribute(:id)
      destination_attribute(:parent_comment_id)
    end

    has_many :votes, Stepvo.Conversation.Vote
  end

  calculations do
    calculate :vote_score, :integer, expr(sum(filter(relationships.votes.value, not is_nil(value))))
    calculate :vote_count, :integer, expr(count(relationships.votes))
  end

  actions do
    create :create do
      primary?(true)
      accept([:content, :user_id, :parent_comment_id])
    end

    defaults([:read, :update, :destroy])
  end

  validations do
    validate(present([:content]))
  end
end
