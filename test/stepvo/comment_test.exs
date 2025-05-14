defmodule Test.Stepvo.CommentTest do
  use Stepvo.DataCase, async: true

  # Alias your Ash API and resources for convenience
  alias Stepvo.Conversation
  alias Stepvo.Conversation.Comment # <-- Uncommented
  alias Stepvo.Conversation.User    # <-- Uncommented
  alias Ash.Changeset # <-- Add alias for Changeset helpers

  # Helper function to quickly create a user for tests
  # test/stepvo/comment_test.exs

 def create_user(attrs \\ %{}) do
  base_attrs = %{
    email: "user-#{System.unique_integer([:positive])}@example.com",
    username: "user-#{System.unique_integer([:positive])}",
    vote_ids: []
  }
  params = Map.merge(base_attrs, attrs)

  case Stepvo.Conversation.User
       |> Ash.Changeset.for_create(:create, params)
       |> Stepvo.Conversation.create() do
    {:ok, user} ->
      user

    {:error, changeset} ->
      flunk("Failed to create user in test helper: #{inspect(changeset)}")
  end
end

  # --- Your Tests Go Here ---

  describe "Comment Creation" do
    test "can create a root comment" do
      user = create_user()

      comment_attrs = %{
        content: "This is a root comment.",
        user_id: user.id
      }

      result = Conversation.create_comment(comment_attrs, actor: user)

      assert {:ok, comment} = result

      assert is_binary(comment.id)
      assert comment.content == "This is a root comment."
      assert comment.user_id == user.id
      assert comment.parent_comment_id == nil
    end

    test "can create a child comment (reply)" do
      user1 = create_user()
      user2 = create_user()

      {:ok, parent_comment} =
        Conversation.create_comment(%{content: "Parent", user_id: user1.id}, actor: user1)

      child_attrs = %{
        content: "This is a reply.",
        user_id: user2.id,
        parent_comment_id: parent_comment.id
      }

      result = Conversation.create_comment(child_attrs, actor: user2)

      assert {:ok, comment} = result
      assert comment.content == "This is a reply."
      assert comment.user_id == user2.id
      assert comment.parent_comment_id == parent_comment.id
    end

    test "cannot create comment with content exceeding max length" do
      user = create_user()
      long_content = String.duplicate("a", 351) # 351 characters

      comment_attrs = %{
        content: long_content,
        user_id: user.id
      }

      result = Conversation.create_comment(comment_attrs, actor: user)

      assert {:error, changeset} = result

# Retrieve all errors from the changeset
# Convert the changeset errors into a readable format
ash_error = Ash.Error.to_ash_error(changeset)

# Find the error for the :content field
content_error = Enum.find(ash_error.errors, fn error ->
  error.field == :content
end)

# Assert that the error exists and the message is correct
assert content_error != nil
assert content_error.message =~ "maximum allowed length is 350"
    end
  end

  # ... other describe blocks ...
end
