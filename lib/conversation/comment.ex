defmodule Stepvo.Conversation.Comment do
  use Ash.Resource,
    domain: Stepvo.Conversation,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "comments"
    repo Stepvo.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :content, :string do
      allow_nil? false
      constraints min_length: 2, max_length: 350
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, Stepvo.Conversation.User do
      destination_attribute :id
      attribute_type :uuid
      allow_nil? false
    end

    belongs_to :parent_comment, Stepvo.Conversation.Comment do
      destination_attribute :id
      source_attribute :parent_comment_id
      attribute_type :uuid
      allow_nil? true
    end



    has_many :child_comments, Stepvo.Conversation.Comment do
      source_attribute :id
      destination_attribute :parent_comment_id
    end

    has_many :votes, Stepvo.Conversation.Vote


  aggregates do
    count :vote_count, :votes
    sum :vote_score, :votes, :value
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end
  end

  validations do
    validate present([:content])

  end

end
