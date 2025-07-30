defmodule StepvoWeb.ConversationLive do
  use StepvoWeb, :live_view

  import Ash.Query
  alias Stepvo.Conversation.Comment
  alias Stepvo.Conversation.User
  alias Stepvo.Conversation.Vote
  alias AshPhoenix.Form
  alias StepvoWeb.ConversationComponents

  @impl true
  def mount(_params, _session, socket) do
    # Load all comments with their relationships and vote scores
    comments_query =
      Comment
      |> Ash.Query.filter(is_nil(parent_comment_id))
      |> load([
        :user,
        :votes,
        child_comments: [
          :user,
          :votes,
          child_comments: [
            :user,
            :votes
          ]
        ]
      ])

    IO.inspect(comments_query, label: "Comments Query")

    case Ash.read(comments_query) do
      {:ok, comments} ->
        IO.inspect(comments, label: "Loaded Comments")

        {:ok,
         socket
         |> assign(:comments, comments)
         |> assign(:page_title, "Stepvo - Hierarchical Conversations")}

      {:error, error} ->
        IO.inspect(error, label: "Error loading comments")

        {:ok,
         socket
         |> assign(:comments, [])
         |> assign(:page_title, "Stepvo - Hierarchical Conversations")
         |> put_flash(:error, "Failed to load comments")}
    end
  end

  @impl true
  def handle_event("vote_comment", %{"comment_id" => comment_id, "value" => value}, socket) do
    vote_value = String.to_integer(value)

    # For now, we'll simulate a user. In a real app, this would come from session
    # alice's ID from our seeded data
    user_id = "c63f1ce3-556a-41de-ae53-feb5b79f9fdb"

    IO.inspect({comment_id, vote_value, user_id}, label: "Processing Vote")

    # Check if user already voted on this comment
    existing_vote_query =
      Vote
      |> Ash.Query.filter(comment_id == ^comment_id and user_id == ^user_id)

    case Ash.read(existing_vote_query) do
      {:ok, [existing_vote]} ->
        # User already voted, update the vote
        if existing_vote.value == vote_value do
          # Same vote, remove it (toggle off)
          case Ash.destroy(existing_vote) do
            :ok ->
              {:noreply, reload_comments(socket) |> put_flash(:info, "Vote removed")}

            {:error, error} ->
              IO.inspect(error, label: "Error removing vote")
              {:noreply, socket |> put_flash(:error, "Failed to remove vote")}
          end
        else
          # Different vote, update it
          case Ash.update(existing_vote, %{value: vote_value}) do
            {:ok, _updated_vote} ->
              {:noreply, reload_comments(socket) |> put_flash(:info, "Vote updated")}

            {:error, error} ->
              IO.inspect(error, label: "Error updating vote")
              {:noreply, socket |> put_flash(:error, "Failed to update vote")}
          end
        end

      {:ok, []} ->
        # No existing vote, create new one
        vote_params = %{
          comment_id: comment_id,
          user_id: user_id,
          value: vote_value
        }

        case Ash.create(Vote, vote_params) do
          {:ok, _vote} ->
            {:noreply, reload_comments(socket) |> put_flash(:info, "Vote recorded")}

          {:error, error} ->
            IO.inspect(error, label: "Error creating vote")
            {:noreply, socket |> put_flash(:error, "Failed to record vote")}
        end

      {:error, error} ->
        IO.inspect(error, label: "Error checking existing vote")
        {:noreply, socket |> put_flash(:error, "Failed to process vote")}
    end
  end

  @impl true
  def handle_event("reply_to_comment", %{"comment_id" => comment_id}, socket) do
    # TODO: Implement reply functionality
    IO.inspect(comment_id, label: "Reply Event")
    {:noreply, socket |> put_flash(:info, "Reply functionality coming soon!")}
  end

  @impl true
  def handle_event("scroll_row", %{"direction" => direction, "row" => row}, socket) do
    # This will be handled by JavaScript in the ConversationTree hook
    IO.inspect({direction, row}, label: "Scroll Event")
    {:noreply, socket}
  end

  # Helper function to reload comments after vote changes
  defp reload_comments(socket) do
    comments_query =
      Comment
      |> Ash.Query.filter(is_nil(parent_comment_id))
      |> load([
        :user,
        :votes,
        child_comments: [
          :user,
          :votes,
          child_comments: [
            :user,
            :votes
          ]
        ]
      ])

    case Ash.read(comments_query) do
      {:ok, comments} ->
        assign(socket, :comments, comments)

      {:error, _error} ->
        socket |> put_flash(:error, "Failed to reload comments")
    end
  end

  # Helper function to calculate vote score for a comment
  defp vote_score(comment) do
    comment.votes
    |> Enum.map(& &1.value)
    |> Enum.sum()
  end

  # Helper function to get user's vote for a comment (if any)
  defp user_vote(comment, user_id) do
    comment.votes
    |> Enum.find(&(&1.user_id == user_id))
  end

  @impl true
  def render(assigns) do
    # For now, hardcode the current user ID (in real app, this would come from session)
    assigns = assign(assigns, :current_user_id, "c63f1ce3-556a-41de-ae53-feb5b79f9fdb")

    ~H"""
    <div class="min-h-screen bg-slate-50 p-4" id="conversation-container" phx-hook="ConversationTree">
      <!-- SVG overlay for connection lines -->
      <svg
        id="connection-lines"
        class="absolute inset-0 pointer-events-none z-10"
        style="width: 100%; height: 100%;"
      >
        <!-- Connection lines will be drawn here by JavaScript -->
      </svg>
      
    <!-- Row 1: Mother Comments (Top Level) -->
      <div class="relative mb-8">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-xl font-semibold text-slate-800">Main Topics</h2>
          <div class="flex space-x-2">
            <button
              phx-click="scroll_row"
              phx-value-direction="left"
              phx-value-row="1"
              class="px-3 py-1 bg-slate-200 hover:bg-slate-300 rounded-lg text-sm font-medium transition-colors"
            >
              ← Left
            </button>
            <button
              phx-click="scroll_row"
              phx-value-direction="right"
              phx-value-row="1"
              class="px-3 py-1 bg-slate-200 hover:bg-slate-300 rounded-lg text-sm font-medium transition-colors"
            >
              Right →
            </button>
          </div>
        </div>

        <div id="row1" class="flex space-x-6 overflow-x-auto pb-4 scroll-smooth">
          <%= for comment <- @comments do %>
            <% score = vote_score(comment) %>
            <% user_vote_val = user_vote(comment, @current_user_id) %>
            <div
              id={"mother-#{comment.id}"}
              class="flex-none w-80 bg-white rounded-xl shadow-lg border border-slate-200 p-6"
            >
              <!-- User info -->
              <div class="flex items-center space-x-3 mb-4">
                <div class="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center">
                  <span class="text-white font-semibold text-sm">
                    {String.first(comment.user.username) |> String.upcase()}
                  </span>
                </div>
                <div>
                  <div class="font-semibold text-slate-800">{comment.user.username}</div>
                  <div class="text-sm text-slate-500">
                    {Calendar.strftime(comment.inserted_at, "%b %d")}
                  </div>
                </div>
              </div>
              
    <!-- Comment content -->
              <div class="mb-4">
                <p class="text-slate-700 leading-relaxed">{comment.content}</p>
              </div>
              
    <!-- Action buttons -->
              <div class="flex items-center justify-between">
                <div class="flex items-center space-x-4">
                  <button
                    phx-click="vote_comment"
                    phx-value-comment_id={comment.id}
                    phx-value-value="1"
                    class={[
                      "flex items-center space-x-1 transition-colors",
                      if(user_vote_val && user_vote_val.value == 1,
                        do: "text-green-600 font-semibold",
                        else: "text-slate-600 hover:text-green-600"
                      )
                    ]}
                  >
                    <span class="text-lg">👍</span>
                    <span class="text-sm">{score}</span>
                  </button>
                  <button
                    phx-click="vote_comment"
                    phx-value-comment_id={comment.id}
                    phx-value-value="-1"
                    class={[
                      "flex items-center space-x-1 transition-colors",
                      if(user_vote_val && user_vote_val.value == -1,
                        do: "text-red-600 font-semibold",
                        else: "text-slate-600 hover:text-red-600"
                      )
                    ]}
                  >
                    <span class="text-lg">👎</span>
                  </button>
                </div>
                <button
                  phx-click="reply_to_comment"
                  phx-value-comment_id={comment.id}
                  class="px-4 py-2 bg-blue-100 hover:bg-blue-200 text-blue-700 rounded-lg text-sm font-medium transition-colors"
                >
                  Reply
                </button>
              </div>
            </div>
          <% end %>
        </div>
      </div>
      
    <!-- Row 2: Child Comments (Second Level) -->
      <div class="relative mb-8">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-lg font-semibold text-slate-700">Responses</h2>
          <div class="flex space-x-2">
            <button
              phx-click="scroll_row"
              phx-value-direction="left"
              phx-value-row="2"
              class="px-3 py-1 bg-slate-200 hover:bg-slate-300 rounded-lg text-sm font-medium transition-colors"
            >
              ← Left
            </button>
            <button
              phx-click="scroll_row"
              phx-value-direction="right"
              phx-value-row="2"
              class="px-3 py-1 bg-slate-200 hover:bg-slate-300 rounded-lg text-sm font-medium transition-colors"
            >
              Right →
            </button>
          </div>
        </div>

        <div id="row2" class="flex space-x-4 overflow-x-auto pb-4 scroll-smooth">
          <%= for comment <- @comments do %>
            <%= for child_comment <- comment.child_comments do %>
              <% score = vote_score(child_comment) %>
              <% user_vote_val = user_vote(child_comment, @current_user_id) %>
              <div
                id={"child-#{child_comment.id}"}
                class="flex-none w-64 bg-white rounded-lg shadow-md border border-slate-100 p-4"
              >
                <!-- User info -->
                <div class="flex items-center space-x-2 mb-3">
                  <div class="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center">
                    <span class="text-white font-semibold text-xs">
                      {String.first(child_comment.user.username) |> String.upcase()}
                    </span>
                  </div>
                  <div>
                    <div class="font-medium text-slate-700 text-sm">
                      {child_comment.user.username}
                    </div>
                    <div class="text-xs text-slate-500">
                      {Calendar.strftime(child_comment.inserted_at, "%b %d")}
                    </div>
                  </div>
                </div>
                
    <!-- Comment content -->
                <div class="mb-3">
                  <p class="text-slate-600 text-sm leading-relaxed">{child_comment.content}</p>
                </div>
                
    <!-- Action buttons -->
                <div class="flex items-center justify-between">
                  <div class="flex items-center space-x-3">
                    <button
                      phx-click="vote_comment"
                      phx-value-comment_id={child_comment.id}
                      phx-value-value="1"
                      class={[
                        "flex items-center space-x-1 transition-colors",
                        if(user_vote_val && user_vote_val.value == 1,
                          do: "text-green-600 font-semibold",
                          else: "text-slate-500 hover:text-green-600"
                        )
                      ]}
                    >
                      <span class="text-sm">👍</span>
                      <span class="text-xs">{score}</span>
                    </button>
                    <button
                      phx-click="vote_comment"
                      phx-value-comment_id={child_comment.id}
                      phx-value-value="-1"
                      class={[
                        "transition-colors",
                        if(user_vote_val && user_vote_val.value == -1,
                          do: "text-red-600 font-semibold",
                          else: "text-slate-500 hover:text-red-600"
                        )
                      ]}
                    >
                      <span class="text-sm">👎</span>
                    </button>
                  </div>
                  <button
                    phx-click="reply_to_comment"
                    phx-value-comment_id={child_comment.id}
                    class="px-3 py-1 bg-blue-50 hover:bg-blue-100 text-blue-600 rounded text-xs font-medium transition-colors"
                  >
                    Reply
                  </button>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
      
    <!-- Row 3: Grandchild Comments (Third Level) -->
      <div class="relative">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-base font-semibold text-slate-600">Follow-ups</h2>
          <div class="flex space-x-2">
            <button
              phx-click="scroll_row"
              phx-value-direction="left"
              phx-value-row="3"
              class="px-3 py-1 bg-slate-200 hover:bg-slate-300 rounded-lg text-sm font-medium transition-colors"
            >
              ← Left
            </button>
            <button
              phx-click="scroll_row"
              phx-value-direction="right"
              phx-value-row="3"
              class="px-3 py-1 bg-slate-200 hover:bg-slate-300 rounded-lg text-sm font-medium transition-colors"
            >
              Right →
            </button>
          </div>
        </div>

        <div id="row3" class="flex space-x-3 overflow-x-auto pb-4 scroll-smooth">
          <%= for comment <- @comments do %>
            <%= for child_comment <- comment.child_comments do %>
              <%= for grandchild_comment <- child_comment.child_comments do %>
                <% score = vote_score(grandchild_comment) %>
                <% user_vote_val = user_vote(grandchild_comment, @current_user_id) %>
                <div
                  id={"grandchild-#{grandchild_comment.id}"}
                  class="flex-none w-52 bg-white rounded-lg shadow-sm border border-slate-50 p-3"
                >
                  <!-- User info -->
                  <div class="flex items-center space-x-2 mb-2">
                    <div class="w-6 h-6 bg-purple-500 rounded-full flex items-center justify-center">
                      <span class="text-white font-semibold text-xs">
                        {String.first(grandchild_comment.user.username) |> String.upcase()}
                      </span>
                    </div>
                    <div>
                      <div class="font-medium text-slate-600 text-xs">
                        {grandchild_comment.user.username}
                      </div>
                      <div class="text-xs text-slate-400">
                        {Calendar.strftime(grandchild_comment.inserted_at, "%b %d")}
                      </div>
                    </div>
                  </div>
                  
    <!-- Comment content -->
                  <div class="mb-2">
                    <p class="text-slate-500 text-xs leading-relaxed">{grandchild_comment.content}</p>
                  </div>
                  
    <!-- Action buttons -->
                  <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-2">
                      <button
                        phx-click="vote_comment"
                        phx-value-comment_id={grandchild_comment.id}
                        phx-value-value="1"
                        class={[
                          "flex items-center space-x-1 transition-colors",
                          if(user_vote_val && user_vote_val.value == 1,
                            do: "text-green-600 font-semibold",
                            else: "text-slate-400 hover:text-green-600"
                          )
                        ]}
                      >
                        <span class="text-xs">👍</span>
                        <span class="text-xs">{score}</span>
                      </button>
                      <button
                        phx-click="vote_comment"
                        phx-value-comment_id={grandchild_comment.id}
                        phx-value-value="-1"
                        class={[
                          "transition-colors",
                          if(user_vote_val && user_vote_val.value == -1,
                            do: "text-red-600 font-semibold",
                            else: "text-slate-400 hover:text-red-600"
                          )
                        ]}
                      >
                        <span class="text-xs">👎</span>
                      </button>
                    </div>
                    <button
                      phx-click="reply_to_comment"
                      phx-value-comment_id={grandchild_comment.id}
                      class="px-2 py-1 bg-blue-50 hover:bg-blue-100 text-blue-500 rounded text-xs font-medium transition-colors"
                    >
                      Reply
                    </button>
                  </div>
                </div>
              <% end %>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
