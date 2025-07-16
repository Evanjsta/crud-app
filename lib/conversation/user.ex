defmodule Stepvo.Conversation.User do
  use Ash.Resource,
    domain: Stepvo.Conversation,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication]

  # --- DSL Sections ---

  postgres do
    table("users")
    repo(Stepvo.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :email, :string do
      allow_nil?(false)
      constraints(trim?: true)
    end

    attribute :username, :string do
      allow_nil?(false)
      constraints(min_length: 3, max_length: 20, trim?: true)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  # AshAuthentication DSL block
  authentication do
    strategies do
      magic_link :magic do
        identity_field(:email)
        sender(Stepvo.Conversation.Senders.SendMagicLink)
      end
    end

    # --- ADD THIS tokens BLOCK BACK ---
    tokens do
      # <-- Must be enabled
      enabled?(true)
      # Ensure this resource exists and is in the domain
      token_resource(Stepvo.Conversation.Token)
      # Example lifetime
      token_lifetime({1, :hours})

      signing_secret(fn _resource, _opts ->
        # Reads from config/dev.exs (or runtime.exs in prod)
        Application.fetch_env!(:stepvo, :token_signing_secret)
      end)
    end

    # --- END tokens BLOCK ---
  end

  # Other Resource Sections
  relationships do
    has_many :comments, Stepvo.Conversation.Comment
    has_many :votes, Stepvo.Conversation.Vote
    # Token relationship usually handled automatically via token_resource
  end

  identities do
    identity(:unique_email, [:email])
    identity(:unique_username, [:username])
  end

  actions do
    defaults([:read, :update, :destroy])

    create :create do
      primary?(true)
      argument(:email, :string, allow_nil?: false)
      argument(:username, :string, allow_nil?: false)
      change(set_attribute(:email, arg(:email)))
      change(set_attribute(:username, arg(:username)))
      # change manage_relationship(:votes, argument: :vote_ids, type: :append_and_remove)
    end
  end

  validations do
    validate(present([:email, :username]))
  end
end
