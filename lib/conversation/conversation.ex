defmodule Stepvo.Conversation do
  use Ash.Domain


  resources do
    resource Stepvo.Conversation.User
    resource Stepvo.Conversation.Comment
    resource Stepvo.Conversation.Vote
    resource Stepvo.Conversation.Token
  end
  
end
