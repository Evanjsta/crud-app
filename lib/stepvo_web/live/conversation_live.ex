defmodule StepvoWeb.ConversationLive do
  use StepvoWeb, :live_view

  import Ash.Query
  on_mount StepvoWeb.UserAuth


  alias Stepvo.Conversation
  alias Stepvo.Conversation.Comment
  alias Stepvo.Conversation.Vote
  alias StepvoWeb.ConversationComponents
  alias AshPhoenix.Form

  # mount/3: Called once when the LiveView process starts for a user session.
  # Its job is to perform initial setup and assign the starting state.
  @impl true
  def mount(_params, _session, socket) do
    # User is assigned by the on_mount hook in the router

    # Build the Ash query for fetching the comments tree
    comments_query = build_comments_query()

    # Read the comments using the query. The API is set within build_comments_query.
    # actor: socket.assigns.current_user # Uncomment and use if read policies need an actor
    IO.inspect(comments_query, label: "Comments Query")
    comments = Ash.read!(comments_query) # Fetch comments without sorting
    sorted_comments = Enum.sort(comments, &(&1.vote_score >= &2.vote_score)) # Manually sort by vote_score
    IO.inspect(sorted_comments, label: "Sorted Comments")


    socket =
      socket
      # Note: current_user is already assigned by on_mount
      |> assign(:comments, sorted_comments)
      |> assign(:replying_to_id, nil)
      |> assign(:reply_form, nil)
      |> assign(:page_title, "Conversation")
      # Store the comments query (which includes recursive load and API) in assigns
      |> assign(:comments_query, comments_query)


    {:ok, socket}
  end

  # render/1: Called initially after mount and whenever assigns change.
  # Its job is to render the HEEx template based on the current assigns.
  @impl true
  def render(assigns) do
    ~H"""
    <.header><%= @page_title %></.header>

    <.flash_group flash={@flash} />

    <div class="mt-6">

      <%!-- Pass all relevant assigns down to the comment_tree component --%>
      <%!-- Use a static ID for the main tree component for stable patching --%>
      <.live_component module={StepvoWeb.ConversationComponents}
        id="comment-tree-root"
        comments={@comments}
        current_user={@current_user}
        replying_to_id={@replying_to_id}
        reply_form={@reply_form}
      />
    </div>

    <%!-- TODO: Maybe add a form here later to create ROOT comments --%>
    """
  end

  # --- Event Handling Callbacks ---

  @impl true
  def handle_event("vote", %{"comment-id" => comment_id, "vote" => vote_str}, socket) do
    with %{} = current_user <- socket.assigns.current_user,
         {vote_value, ""} <- Integer.parse(vote_str) do

      vote_params = %{user_id: current_user.id, comment_id: comment_id, value: vote_value}

      vote_changeset =
        Stepvo.Conversation.Vote
        |> Ash.Changeset.for_create(:create, vote_params, actor: current_user)

      case Ash.create(vote_changeset, api: Stepvo.Conversation) do
        {:ok, _vote} ->
          {:noreply, put_flash(socket, :info, "Vote registered successfully.")}

        {:error, changeset} ->
          error_msg =
            changeset.errors
            |> Enum.map(fn {field, {message, _opts}} -> "#{field}: #{message}" end)
            |> Enum.join(", ")
            |> Kernel.||("Could not register vote.")

          {:noreply, put_flash(socket, :error, "Error voting: #{error_msg}")}
      end
    else
      _ ->
        {:noreply, put_flash(socket, :error, "You must be logged in to vote.")}
    end
  end

  @impl true
  def handle_event("show_reply_form", %{"comment-id" => comment_id}, socket) do
    if socket.assigns.current_user do
      # Use Comment alias. Keep api: Conversation here, as AshPhoenix.Form.for_create expects the API
      form = AshPhoenix.Form.for_create(Comment, :create, api: Conversation, params: %{parent_comment_id: comment_id})
      socket =
        socket
        |> assign(:replying_to_id, comment_id)
        |> assign(:reply_form, form)
      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, "You must be logged in to reply.")}
    end
  end

  @impl true
  def handle_event("hide_reply_form", %{"comment-id" => _comment_id}, socket) do
    socket =
      socket
      |> assign(:replying_to_id, nil)
      |> assign(:reply_form, nil)
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_reply", %{"comment" => comment_params}, socket) do
     # Use Form alias
     form = AshPhoenix.Form.validate(socket.assigns.reply_form, comment_params)
     {:noreply, assign(socket, :reply_form, form)}
  end

  @impl true
  def handle_event("save_reply", %{"comment" => comment_params}, socket) do
     with %{} = current_user <- socket.assigns.current_user,
          %{} = form <- socket.assigns.reply_form do

       # Use Form alias
       # Keep api: Conversation here, as AshPhoenix.Form.submit expects the API
       case AshPhoenix.Form.submit(form, params: comment_params, actor: current_user, api: Conversation) do
         {:ok, _new_comment} -> # New comment successfully created!

           # --- Start: Logic to dynamically update comments list ---

           # Re-fetch the entire conversation tree.
           # Use the comments_query defined in mount for consistency.
           # The API is already set within the query object stored in assigns.
           updated_comments = Ash.read!(socket.assigns.comments_query) # Correct: Removed api: option here

           socket =
             socket
             |> assign(:comments, updated_comments) # Update the main comments assign
             |> assign(:replying_to_id, nil) # Hide the form
             |> assign(:reply_form, nil) # Clear the form state
             |> put_flash(:info, "Reply posted!") # Show success message

           # --- End: Logic to dynamically update comments list ---

           {:noreply, socket}

         {:error, form} ->
           # If there's a validation error, update the form assign to display errors
           {:noreply, assign(socket, :reply_form, form)}
        end
     else
         _ ->
        # This 'else' handles cases where current_user or reply_form were nil
        {:noreply, put_flash(socket, :error, "Could not save reply. Please try again.")}
     end
  end

  # Helper function to define the comments query
  defp build_comments_query do
    Stepvo.Conversation.Comment
    |> Ash.Query.do_filter(parent_comment_id: nil) # Filter for root comments
    |> Ash.Query.load([
      :user, # Load the user for the current comment
      :vote_score, # Load the vote score for the current comment
      child_comments: [:user, :vote_score] # Specify what to load for child comments
    ])
    |> Ash.Query.set_domain(Stepvo.Conversation) # Correct: Set the domain on the query
 end

end
