defmodule Stepvo.Conversation.Vote do
  use Ash.Resource,
    domain: Stepvo.Conversation,
    data_layer: AshPostgres.DataLayer

    postgres do
      table "votes"
      repo Stepvo.Repo
    end

    attributes do
      uuid_primary_key :id

      attribute :value, :integer do
        allow_nil? false
        constraints min: -1, max: 1
      end

      create_timestamp :inserted_at

    end

    relationships do
      belongs_to :user, Stepvo.Conversation.User do
        attribute_type :uuid
        allow_nil? false
      end

      belongs_to :comment, Stepvo.Conversation.Comment do
        attribute_type :uuid
        allow_nil? false
      end
      
    end

    identities do
      identity :unique_user_comment_vote, [:user_id, :comment_id]
    end

    actions do
      defaults [:create, :read, :destroy]
    end

    validations do
      validate present([:value, :user_id, :comment_id])
      validate one_of(:value, [1, -1])
    end

end
