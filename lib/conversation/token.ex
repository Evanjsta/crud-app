defmodule Stepvo.Conversation.Token do
  use Ash.Resource,
  extensions: [AshAuthentication.TokenResource],
  domain: Stepvo.Conversation,
  data_layer: AshPostgres.DataLayer


 postgres do
   table "tokens"
   repo Stepvo.Repo
 end
  # The TokenResource extension defines all necessary attributes (like jti, subject, expires_at)
  # and actions (like :store_token, :revoke_token, :get_confirmation_changes) automatically.
end
