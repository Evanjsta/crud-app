defmodule StepvoWeb.ConversationLive do
  use StepvoWeb, :live_view

  import Ash.Query
  alias Stepvo.Conversation.Comment
  alias Stepvo.Conversation.User
  alias Stepvo.Conversation.Vote
  alias AshPhoenix.Form
  alias StepvoWeb.ConversationComponents

  # Add on_mount hook for debugging
  @impl true
  def on_mount(:default, _params, session, socket) do
    IO.inspect(session, label: "Session in on_mount")
    {:ok, socket}
  end

  @impl true
  def mount(_params, _session, socket) do
    comments_query =
      Comment
      |> Ash.Query.filter(is_nil(parent_comment_id))
      |> Ash.Query.sort(inserted_at: :desc)
      |> Ash.Query.load([:user, :votes])
      |> Ash.Query.load(child_comments: [:user, :votes])
      |> Ash.Query.load_aggregates([:vote_score, :vote_count])
      |> Ash.Query.load(child_comments: fn query ->
        query
        |> Ash.Query.load_aggregates([:vote_score, :vote_count])
      end)

      IO.inspect(comments_query, label: "Query before execution")

      case Ash.read(comments_query) do
      {:ok, comments} ->
        IO.inspect(comments, label: "Comments from database")
        {:ok,
         socket
         |> assign(:comments, comments)
         |> assign(:page_title, "Stepvo - Hierarchical Conversations")}

      {:error, error} ->
        IO.inspect(error, label: "Error reading comments")
        {:ok,
         socket
         |> assign(:comments, [])
         |> assign(:page_title, "Stepvo - Hierarchical Conversations")
         |> put_flash(:error, "Failed to load comments: #{inspect(error)}")}
    end
  end

  defp wait_for_apps(apps) do
    Enum.each(apps, fn app ->
      if Application.get_env(app, :started) != true do
        :timer.sleep(50)
        wait_for_apps(apps)
      end
    end)
  end

  defp reload_comments(socket) do
    comments_query =
      Comment
      |> Ash.Query.filter(is_nil(parent_comment_id))
      |> Ash.Query.sort(inserted_at: :desc)
      |> Ash.Query.load([:user, :votes])
      |> Ash.Query.load(child_comments: [:user, :votes])
      |> Ash.Query.load_aggregates([:vote_score, :vote_count])
      |> Ash.Query.load(child_comments: fn query ->
        query
        |> Ash.Query.load_aggregates([:vote_score, :vote_count])
      end)

    case Ash.read(comments_query) do
      {:ok, comments} ->
        assign(socket, :comments, comments)

      {:error, _error} ->
        socket |> put_flash(:error, "Failed to reload comments")
    end
  end

  # --- Keep all your other functions below this line ---

  @impl true
  def handle_event("vote_comment", %{"comment_id" => comment_id, "value" => value}, socket) do
    vote_value = String.to_integer(value)
    # This user_id is a placeholder and should be replaced with actual session logic
    user_id = "c63f1ce3-556a-41de-ae53-feb5b79f9fdb"

    existing_vote_query =
      Vote
      |> Ash.Query.filter(comment_id == ^comment_id and user_id == ^user_id)

    case Ash.read(existing_vote_query) do
      {:ok, [existing_vote]} ->
        if existing_vote.value == vote_value,
          do: Ash.destroy(existing_vote),
          else: Ash.update(existing_vote, %{value: vote_value})

      {:ok, []} ->
        Ash.create(Vote, %{comment_id: comment_id, user_id: user_id, value: vote_value})
    end

    {:noreply, reload_comments(socket)}
  end

  @impl true
  def handle_event("reply_to_comment", %{"comment_id" => comment_id}, socket) do
    IO.inspect(comment_id, label: "Reply Event")
    {:noreply, socket |> put_flash(:info, "Reply functionality coming soon!")}
  end

  defp vote_score(comment) do
    comment.votes |> Enum.map(& &1.value) |> Enum.sum()
  end

  defp user_vote(comment, user_id) do
    comment.votes |> Enum.find(&(&1.user_id == user_id))
  end

  @impl true
  def render(assigns) do
    # Add debugging
    IO.inspect(assigns.comments, label: "Comments in LiveView render")

    assigns = assign(assigns, :current_user_id, "c63f1ce3-556a-41de-ae53-feb5b79f9fdb")

    ~H"""
    <div class="min-h-screen bg-slate-50 p-4" id="conversation-container" phx-hook="ConversationTree">
      <h2 class="text-xl font-semibold text-slate-800 mb-4">Conversation</h2>

      <%!-- Add debug output to page --%>
      <pre class="bg-gray-100 p-4 mb-4">
        <%= inspect(@comments) %>
      </pre>

      <ConversationComponents.comment_tree
        comments={@comments}
        current_user_id={@current_user_id}
      />
      <svg
        id="connection-lines"
        class="absolute inset-0 pointer-events-none z-0"
        style="width: 100%; height: 100%;"
      >
      </svg>
    </div>
    """
  end
end
