defmodule StepvoWeb.ConversationComponents do
  use StepvoWeb, :component

  @doc """
  Renders the initial list of top-level comments by calling the recursive node.
  """
  def comment_tree(assigns) do
    ~H"""
    <div :for={comment <- @comments}>
      <.comment_card
        comment={comment}
        current_user_id={@current_user_id}
      />

      <%= if is_list(comment.child_comments) and comment.child_comments != [] do %>
        <div class="ml-6 border-l-2 border-gray-100 pl-4">
          <.comment_tree
            comments={comment.child_comments}
            current_user_id={@current_user_id}
          />
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders a single comment card with its content, metadata, and actions.
  """
  def comment_card(assigns) do
    ~H"""
    <div
      id={"comment-#{@comment.id}"}
      class="comment-card bg-white rounded-lg shadow-md p-4 mb-4 border border-slate-200"
    >
      <p class="text-gray-800 leading-relaxed"><%= @comment.content %></p>

      <div class="flex items-center justify-between mt-3">
        <div class="flex items-center space-x-4 text-xs text-gray-500">
          <span class="font-medium text-gray-700">
            <%= (@comment.user && @comment.user.username) || "Unknown" %>
          </span>
          <span>Score: <%= @comment.vote_score || 0 %></span>
        </div>

        <div class="flex items-center space-x-2">
          <button
            phx-click="vote"
            phx-value-comment-id={@comment.id}
            phx-value-value="1"
            class="text-gray-400 hover:text-green-600 transition-colors"
          >
            ↑
          </button>

          <button
            phx-click="vote"
            phx-value-comment-id={@comment.id}
            phx-value-value="-1"
            class="text-gray-400 hover:text-red-600 transition-colors"
          >
            ↓
          </button>

          <button
            :if={@current_user_id}
            phx-click="reply_to_comment"
            phx-value-comment-id={@comment.id}
            class="text-xs text-blue-600 hover:text-blue-700 transition-colors"
          >
            Reply
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Recursively renders a single comment and its children in horizontal "steps".
  """
  def comment_node(assigns) do
    ~H"""
    <div class="w-full">
      <div
        id={"comment-#{@comment.id}"}
        data-level={@level}
        data-parent-id={if @comment.parent_comment_id, do: "comment-#{@comment.parent_comment_id}"}
        class="comment-card inline-block align-top bg-white rounded-lg shadow-md p-4 mb-4 border border-slate-200"
        style="width: 350px;"
      >
        <p class="text-gray-800 leading-relaxed"><%= @comment.content %></p>
        <div class="flex items-center space-x-4 mt-3 text-xs text-gray-500">
          <span class="font-medium text-gray-700">
            <%= (@comment.user && @comment.user.username) || "Unknown" %>
          </span>
          <button
            :if={@current_user_id}
            phx-click="reply_to_comment"
            phx-value-comment-id={@comment.id}
            class="hover:text-blue-600 transition-colors"
          >
            Reply
          </button>
        </div>
      </div>

      <div :if={@comment.child_comments != []} class="step-container pl-12">
        <div class="flex flex-row items-start space-x-4 overflow-x-auto py-4">
          <.comment_node
            :for={child <- @comment.child_comments}
            comment={child}
            level={@level + 1}
            current_user_id={@current_user_id}
          />
        </div>
      </div>
    </div>
    """
  end
end
