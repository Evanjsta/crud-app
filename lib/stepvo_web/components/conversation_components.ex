defmodule StepvoWeb.ConversationComponents do
  use StepvoWeb, :component

  alias Stepvo.Conversation.Comment
  alias Stepvo.Conversation.User
  alias AshPhoenix.Form
  alias StepvoWeb.CoreComponents

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Comment Tree Component - matches our static mockup design
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  @doc """
  Renders a list of comments and their nested children recursively.
  """
  @spec comment_tree(map) :: term()
  def comment_tree(assigns) do
    # Required Assigns: comments (list of %Comment{}), current_user, replying_to_id, reply_form
    ~H"""
    <div :for={comment <- @comments}>
      <.comment_card
        comment={comment}
        current_user={@current_user}
        replying_to_id={@replying_to_id}
        reply_form={@reply_form}
      />

      <div :if={comment.child_comments != []} class="ml-6 border-l-2 border-gray-100 pl-4">
        <.comment_tree
          comments={comment.child_comments}
          current_user={@current_user}
          replying_to_id={@replying_to_id}
          reply_form={@reply_form}
        />
      </div>
    </div>
    """
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Comment Card Component - matches our static mockup design
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  @doc """
  Renders a single comment card with content, metadata, and actions.
  Matches the exact design from our static mockup.
  """
  @spec comment_card(map) :: term()
  def comment_card(assigns) do
    ~H"""
    <div
      class="comment-item bg-white rounded-lg border border-gray-200 p-4 mb-4"
      id={"comment-#{@comment.id}"}
    >
      <div class="flex items-start space-x-3">
        <!-- Vote controls -->
        <div class="flex flex-col items-center space-y-1 mt-1">
          <button
            phx-click="vote"
            phx-value-comment-id={@comment.id}
            phx-value-vote="1"
            class="text-gray-400 hover:text-green-600 transition-colors"
          >
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
              <path
                fill-rule="evenodd"
                d="M14.707 12.707a1 1 0 01-1.414 0L10 9.414l-3.293 3.293a1 1 0 01-1.414-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 010 1.414z"
                clip-rule="evenodd"
              >
              </path>
            </svg>
          </button>
          <span class="text-sm font-medium text-gray-700">+{@comment.vote_score || 0}</span>
          <button
            phx-click="vote"
            phx-value-comment-id={@comment.id}
            phx-value-vote="-1"
            class="text-gray-400 hover:text-red-600 transition-colors"
          >
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
              <path
                fill-rule="evenodd"
                d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
                clip-rule="evenodd"
              >
              </path>
            </svg>
          </button>
        </div>
        
    <!-- Comment content -->
        <div class="flex-1">
          <div class="prose prose-sm max-w-none">
            <p class="text-gray-800 leading-relaxed">
              {@comment.content}
            </p>
          </div>

          <div class="flex items-center space-x-4 mt-3 text-xs text-gray-500">
            <span class="font-medium text-gray-700">
              {(@comment.user && @comment.user.username) || "Unknown"}
            </span>
            <span>{format_time_ago(@comment.inserted_at)}</span>
            <button
              :if={@current_user}
              phx-click="show_reply_form"
              phx-value-comment-id={@comment.id}
              class="hover:text-blue-600 transition-colors"
            >
              Reply
            </button>
          </div>
          
    <!-- Reply form if currently replying to this comment -->
          <.maybe_show_reply_form
            comment={@comment}
            current_user={@current_user}
            replying_to_id={@replying_to_id}
            form={@reply_form}
          />
        </div>
      </div>
    </div>
    """
  end

  # --- Private Helper for Conditionally Showing Reply Form ---
  @doc false
  defp maybe_show_reply_form(assigns) do
    # Required Assigns: comment, current_user, replying_to_id, form
    ~H"""
    <div :if={@current_user && @replying_to_id == @comment.id}>
      <.comment_form
        parent_comment_id={@comment.id}
        current_user={@current_user}
        form_id={"reply-form-#{@comment.id}"}
        form={@form}
      />
    </div>
    """
  end

  # --- Private Helper for the Comment Form itself ---
  @doc false
  defp comment_form(assigns) do
    # Required Assigns: parent_comment_id, current_user, form_id, form
    ~H"""
    <div class="mt-4 ml-8 pl-4 border-l-2 border-gray-200">
      <.simple_form
        :if={@form}
        for={@form}
        id={@form_id}
        phx-submit="save_reply"
        phx-change="validate_reply"
        phx-value-parent-id={@parent_comment_id}
        class="space-y-3"
      >
        <.input
          field={@form[:content]}
          type="textarea"
          label="Your Reply"
          placeholder="Add your comment..."
          class="text-sm border-gray-300 rounded-lg focus:border-blue-500 focus:ring-blue-500 bg-white text-gray-900 placeholder-gray-500 px-3 py-2"
        />
        <div class="flex space-x-2">
          <button
            type="submit"
            class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm font-medium"
          >
            Submit Reply
          </button>
          <button
            type="button"
            phx-click="hide_reply_form"
            phx-value-comment-id={@parent_comment_id}
            class="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors text-sm font-medium"
          >
            Cancel
          </button>
        </div>
      </.simple_form>
    </div>
    """
  end

  # Helper function to format time
  defp format_time_ago(nil), do: "unknown"

  defp format_time_ago(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      diff < 604_800 -> "#{div(diff, 86400)}d ago"
      true -> "#{div(diff, 604_800)}w ago"
    end
  end
end
