defmodule StepvoWeb.ConversationComponents do
  use StepvoWeb, :component
  # If using @derive {Phoenix.Component, required_assigns: ...}
  # use StepvoWeb, :verified_component

  # TODO: Uncomment these aliases when needed
  # alias Stepvo.Conversation.Comment
  # alias Stepvo.Conversation.User
  # alias AshPhoenix.Form
  # alias StepvoWeb.CoreComponents # Or MishkaChelekom if using their form components

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Comment Card Component and its Private Helpers
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  @doc """
  Renders a single comment card with content, metadata, and actions.

  Requires preloading on the comment struct: `:user`, `:vote_score`.
  Consider preloading votes associated with the `current_user` if displaying
  active vote states on buttons is desired.

  Assigns:
    - comment (required): The %Comment{} struct to display.
    - current_user (required): The currently logged-in %User{} or nil.
    - replying_to_id (optional): The ID of the comment the parent LiveView
      is currently showing the reply form for. Defaults to nil.
    - reply_form (optional): The %AshPhoenix.Form{} struct for the reply form,
      managed by the parent LiveView. Required if replying_to_id matches comment.id.
  """
  @spec comment_card(map) :: term() # Correct return type hint
  # Uncomment and list required assigns if using :verified_component
  # @derive {Phoenix.Component, required_assigns: [:comment, :current_user]}
  def comment_card(assigns) do
    ~H"""
    <div class="comment-card border border-gray-200 rounded-lg shadow-sm p-4 my-3 bg-white" id={"comment-#{@comment.id}"}>
      <.comment_content comment={@comment} />
      <.comment_meta comment={@comment} />
      <.comment_actions comment={@comment} current_user={@current_user} />

      <.maybe_show_reply_form
        comment={@comment}
        current_user={@current_user}
        replying_to_id={@replying_to_id}
        form={@reply_form}
      />
    </div>
    """
  end

  # --- Private Helper Functions for comment_card ---

  @doc false
  defp comment_content(assigns) do
    ~H"""
    <p class="text-gray-800 mb-2 text-base"><%= @comment.content %></p>
    """
  end

  @doc false
  defp comment_meta(assigns) do
    ~H"""
    <div class="text-xs text-gray-500 border-t border-gray-100 pt-2 mt-2"> <%!-- Changed <.div to <div --%>
      <span>Posted by: <span class="font-medium text-gray-700"><%= @comment.user && @comment.user.username || "Unknown" %></span></span>
      <span class="ml-4">Score: <span class="font-semibold text-gray-800"><%= @comment.vote_score || 0 %></span></span>
      <%!-- Maybe add timestamp later: <.human_time datetime={@comment.inserted_at} /> --%>
    </div>
    """
  end

  @doc false
  defp comment_actions(assigns) do
    ~H"""
    <div :if={@current_user} class="flex items-center space-x-1 mt-3"> <!-- Changed <.div to <div -->
      <.vote_button comment_id={@comment.id} vote_value={1} />
      <.vote_button comment_id={@comment.id} vote_value={-1} />

      <.button phx-click="show_reply_form" phx-value-comment-id={@comment.id} class="ml-2">
        Reply
      </.button>

      <%!-- Add edit/delete buttons later based on policy checks --%>
    </div>
    """
  end

  # --- Private Helper for Voting Buttons ---
  @doc false
  defp vote_button(assigns) do
    # Required Assigns: comment_id, vote_value (1 or -1)
    # Access vote_value from assigns map, not as @vote_value
    vote_value = assigns[:vote_value] # Corrected access

    # Calculate values
    icon_name = if vote_value == 1, do: "hero-arrow-up-solid", else: "hero-arrow-down-solid"
    label_text = if vote_value == 1, do: "Upvote", else: "Downvote"
    color_class = "text-gray-500 hover:text-gray-700 focus:text-gray-700" # Default state
    # TODO: Add logic here later if you pass in the user's current vote for this comment
    # active_class = if assigns[:current_user_vote] == vote_value, do: "text-indigo-600", else: color_class

    # Assign calculated values back to assigns for use in HEEx
    assigns =
      assigns
      |> assign_new(:icon_name, fn -> icon_name end) # Use assign_new or assign
      |> assign_new(:label_text, fn -> label_text end)
      |> assign_new(:color_class, fn -> color_class end)

    ~H"""
    <.button
      phx-click="vote"
      phx-value-comment-id={@comment_id}
      phx-value-vote={@vote_value}
      aria-label={@label_text}
      class={"!p-1 #{@color_class}"}
      >
      <.icon name={@icon_name} class="h-4 w-4" />
    </.button>
    """
    # size="xs"
    # kind="ghost" this is in case these attributes are needed later.
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
    # Needs: `:form` assign passed down from LiveView containing the AshPhoenix.Form struct

    # REMOVED: form = assigns[:form] || nil (Unused variable)

    ~H"""
    <div class="mt-4 ml-8 pl-4 border-l-2 border-gray-200">
      <.simple_form
          :if={@form}
          for={@form}
          id={@form_id}
          phx-submit="save_reply"
          phx-change="validate_reply"
          phx-value-parent-id={@parent_comment_id}
          >
            <.input field={@form[:content]} type="textarea" label="Your Reply" placeholder="Add your comment..." class="text-sm"/>
            <.button type="submit">Submit Reply</.button>
            <.button type="button" phx-click="hide_reply_form" phx-value-comment-id={@parent_comment_id} class="ml-2">Cancel</.button>
      </.simple_form>
    </div>
    """
    # Replace <.simple_form> and <.input> with components from CoreComponents or Chelekom UI
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Comment Tree Component (from previous example, uses comment_card)
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
          reply_form={@reply_form} />


    <div :if={comment.child_comments != []} class="ml-4 lg:ml-6">
      <.comment_tree
          comments={comment.child_comments}
          current_user={@current_user}
          replying_to_id={@replying_to_id}
          reply_form={@reply_form}/>
      </div>
    </div>
    """
  end

  # --- Add other conversation-related components below ---

end
