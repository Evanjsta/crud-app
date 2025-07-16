# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Stepvo.Repo.insert!(%Stepvo.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Create some sample users
{:ok, alice} =
  Stepvo.Conversation.User
  |> Ash.Changeset.for_create(:create, %{
    email: "alice@example.com",
    username: "alice"
  })
  |> Ash.create(domain: Stepvo.Conversation)

{:ok, bob} =
  Stepvo.Conversation.User
  |> Ash.Changeset.for_create(:create, %{
    email: "bob@example.com",
    username: "bob"
  })
  |> Ash.create(domain: Stepvo.Conversation)

# Create some root comments
{:ok, comment1} =
  Stepvo.Conversation.Comment
  |> Ash.Changeset.for_create(:create, %{
    content: "What's everyone's thoughts on the future of AI?",
    user_id: alice.id
  })
  |> Ash.create(domain: Stepvo.Conversation)

{:ok, comment2} =
  Stepvo.Conversation.Comment
  |> Ash.Changeset.for_create(:create, %{
    content: "I think Phoenix LiveView is revolutionary for real-time web apps.",
    user_id: bob.id
  })
  |> Ash.create(domain: Stepvo.Conversation)

# Create some child comments
{:ok, _reply1} =
  Stepvo.Conversation.Comment
  |> Ash.Changeset.for_create(:create, %{
    content: "I believe AI will augment human capabilities rather than replace them.",
    user_id: bob.id,
    parent_comment_id: comment1.id
  })
  |> Ash.create(domain: Stepvo.Conversation)

{:ok, _reply2} =
  Stepvo.Conversation.Comment
  |> Ash.Changeset.for_create(:create, %{
    content: "Totally agree! The real-time updates without JavaScript are amazing.",
    user_id: alice.id,
    parent_comment_id: comment2.id
  })
  |> Ash.create(domain: Stepvo.Conversation)

IO.puts("Seeded database with sample conversation data!")
