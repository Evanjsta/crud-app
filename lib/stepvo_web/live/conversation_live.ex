defmodule StepvoWeb.ConversationLive do
  # Sets up this module as a LiveView, bringing in necessary behaviours
  # and functions from Phoenix.LiveView and helpers from StepvoWeb.
  use StepvoWeb, :live_view

  # REMOVED: import StepvoWeb.ConversationComponents (Use Alias or full name)

  # Aliases for easier access to modules we'll use frequently.
  alias Stepvo.Conversation         # Your Ash API module
  alias Stepvo.Conversation.Comment # UNCOMMENTED: Your Ash Resources
  alias StepvoWeb.ConversationComponents # Your component module (Keep this)

  # mount/3: Called once when the LiveView process starts for a user session.
  # Its job is to perform initial setup and assign the starting state.
  @impl true
  def mount(_params, _session, socket) do
    # User is assigned by the on_mount hook in the router

    comments =
      Stepvo.Conversation.Comment
        |> Ash.Query.do_filter(parent_comment_id: nil)
        |> Ash.Query.load([
          :user,
          :vote_score,
          child_comments: [
            sort: [desc: :vote_score],
            load: [:user, :vote_score]
          ]
        ])
        |> Ash.read!(Stepvo.Conversation)
        # actor: socket.assigns.current_user # Use if read policies need actor


    socket =
      socket
      # Note: current_user is already assigned by on_mount
      |> assign(:comments, comments)
      |> assign(:replying_to_id, nil)
      |> assign(:reply_form, nil)
      |> assign(:page_title, "Conversation")

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

      <ConversationComponents.comment_tree
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

      case Ash.create(vote_changeset) do
        {:ok, _vote} ->
          {:noreply, put_flash(socket, :info, "Vote registered successfully.")}

        {:error, changeset} ->
          error_msg =
            changeset.errors
            |> Enum.map(fn {field, {message, _opts}} -> "#{field}: #{message}" end)
            |> Enum.join(", ")
            |> Kernel.||("Could not register vote.")

          {:noreply, put_flash(socket, :error, error_msg)}

      end
    else
      _->
        {:noreply, put_flash(socket, :error, "You must be logged in to vote.")}
    end
  end

  @impl true
  def handle_event("show_reply_form", %{"comment-id" => comment_id}, socket) do
    if socket.assigns.current_user do
      # Use Comment alias
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
     # CORRECTED: Removed the case statement
     form = AshPhoenix.Form.validate(socket.assigns.reply_form, comment_params)
     {:noreply, assign(socket, :reply_form, form)}
  end

  @impl true
  def handle_event("save_reply", %{"comment" => comment_params}, socket) do
     with %{} = current_user <- socket.assigns.current_user,
          %{} = form <- socket.assigns.reply_form do

      # Use Form alias
      case AshPhoenix.Form.submit(form, params: comment_params, actor: current_user, api: Conversation) do
        {:ok, _} ->
          socket =
            socket
            |> assign(:replying_to_id, nil)
            |> assign(:reply_form, nil)
            |> put_flash(:info, "Reply posted!")
          # TODO: Update @comments assign to show the new reply
          {:noreply, socket}
        {:error, form} ->
          {:noreply, assign(socket, :reply_form, form)}
       end
     else
        _ ->
          {:noreply, put_flash(socket, :error, "Could not save reply.")}
     end
  end
end
