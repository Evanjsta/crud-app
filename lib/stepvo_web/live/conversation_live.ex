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
    # Fetch comments without sorting
    comments = Ash.read!(comments_query)
    # Manually sort by vote_score
    sorted_comments = Enum.sort(comments, &(&1.vote_score >= &2.vote_score))
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
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Stepvo - Hierarchical Comment System</title>
        <!-- Tailwind CSS for styling -->
        <script src="https://cdn.tailwindcss.com">
        </script>
        <!-- Google Fonts for a minimalist look -->
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap"
          rel="stylesheet"
        />
        <style>
          .no-scrollbar::-webkit-scrollbar { display: none; }
          .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
          body { font-family: 'Inter', sans-serif; }
          /* Style for the connecting lines */
          .connector-line {
              stroke: #cbd5e1; /* slate-300 */
              stroke-width: 2;
              fill: none;
          }
        </style>
      </head>
      <body class="bg-slate-50 text-slate-800 antialiased">
        
    <!-- Main container with relative positioning for SVG lines -->
        <div
          id="main-container"
          class="relative container mx-auto p-4 md:p-8"
          phx-hook="ConversationTree"
        >
          
    <!-- SVG container for drawing lines. It will overlay the content. -->
          <svg
            id="svg-connectors"
            class="absolute top-0 left-0 w-full h-full"
            style="pointer-events: none;"
          >
          </svg>

          <div class="space-y-12">
            <!-- SECTION: Top Row (Mother Comment) -->
            <div class="row-container">
              <div class="flex items-center space-x-2">
                <div
                  id="row1"
                  class="flex-1 flex gap-6 overflow-x-hidden no-scrollbar scroll-smooth justify-center"
                >
                  <div
                    id="mother-comment"
                    class="comment-box flex-shrink-0 w-full md:w-10/12 lg:w-8/12 bg-white border border-slate-200 rounded-lg p-6 shadow-md"
                  >
                    <p class="comment-text text-base text-slate-700 leading-relaxed">
                      This is the "mother" comment, the origin of the entire discussion. It poses the initial question or topic. All comments in the row directly below are direct responses to this one. The visual goal is to show a clear, top-down flow of conversation.
                    </p>
                    <div class="flex items-center justify-between mt-5">
                      <div class="flex items-center gap-4 text-slate-400">
                        <button class="hover:text-green-500 transition-colors" aria-label="Upvote">
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="20"
                            height="20"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                          >
                            <path d="M7 11v4a1 1 0 0 0 1 1h3a1 1 0 0 0 1-1v-4a1 1 0 0 0-1-1H8a1 1 0 0 0-1 1z" />
                            <path d="M12 7.5a2.5 2.5 0 0 1 0 5" />
                            <path d="M17 8v8" />
                            <path d="M21 7.5a2.5 2.5 0 0 0-5 0v1a2.5 2.5 0 0 0 5 0" />
                          </svg>
                        </button>
                        <span class="font-semibold text-sm text-slate-500">128</span>
                        <button class="hover:text-red-500 transition-colors" aria-label="Downvote">
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="20"
                            height="20"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                          >
                            <path d="M7 13v-4a1 1 0 0 1 1-1h3a1 1 0 0 1 1 1v4a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1z" />
                            <path d="M12 16.5a2.5 2.5 0 0 0 0-5" />
                            <path d="M17 16V8" />
                            <path d="M21 16.5a2.5 2.5 0 0 1-5 0v-1a2.5 2.5 0 0 1 5 0" />
                          </svg>
                        </button>
                      </div>
                      <div class="flex items-center gap-2">
                        <button class="px-4 py-2 text-sm font-semibold bg-blue-500 text-white rounded-md hover:bg-blue-600">
                          Reply
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
    <!-- SECTION: Middle Row (Child Comments) -->
            <div class="row-container">
              <div class="flex items-center space-x-2">
                <div id="row2" class="flex-1 flex gap-4 overflow-x-hidden no-scrollbar scroll-smooth">
                  <div
                    id="child-comment-1"
                    class="comment-box flex-shrink-0 w-5/6 md:w-2/5 lg:w-[32%] bg-white border border-slate-200 rounded-lg p-5 shadow-sm"
                  >
                    <p class="comment-text text-sm text-slate-600 leading-relaxed">
                      This is the first "child" comment, a direct reply to the mother comment above. It offers one perspective or answer. Other boxes in this row are sibling comments, also replying to the same mother comment.
                    </p>
                    <div class="flex items-center justify-between mt-4">
                      <div class="flex items-center gap-3 text-slate-400">
                        <button
                          phx-click="vote"
                          phx-value-comment-id="child-1"
                          phx-value-vote="1"
                          class="hover:text-green-500"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="18"
                            height="18"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                          >
                            <path d="M7 11v4a1 1 0 0 0 1 1h3a1 1 0 0 0 1-1v-4a1 1 0 0 0-1-1H8a1 1 0 0 0-1 1z" />
                            <path d="M12 7.5a2.5 2.5 0 0 1 0 5" />
                            <path d="M17 8v8" />
                            <path d="M21 7.5a2.5 2.5 0 0 0-5 0v1a2.5 2.5 0 0 0 5 0" />
                          </svg>
                        </button>
                        <span class="font-semibold text-xs text-slate-500">98</span>
                        <button
                          phx-click="vote"
                          phx-value-comment-id="child-1"
                          phx-value-vote="-1"
                          class="hover:text-red-500"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="18"
                            height="18"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                          >
                            <path d="M7 13v-4a1 1 0 0 1 1-1h3a1 1 0 0 1 1 1v4a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1z" />
                            <path d="M12 16.5a2.5 2.5 0 0 0 0-5" />
                            <path d="M17 16V8" />
                            <path d="M21 16.5a2.5 2.5 0 0 1-5 0v-1a2.5 2.5 0 0 1 5 0" />
                          </svg>
                        </button>
                      </div>
                      <div class="flex items-center gap-2">
                        <button
                          phx-click="show_reply_form"
                          phx-value-comment-id="child-1"
                          class="px-3 py-1.5 text-xs font-semibold bg-slate-200 text-slate-700 rounded-md hover:bg-slate-300"
                        >
                          Reply
                        </button>
                      </div>
                    </div>
                  </div>
                  <div
                    id="child-comment-2"
                    class="comment-box flex-shrink-0 w-5/6 md:w-2/5 lg:w-[32%] bg-white border border-slate-200 rounded-lg p-5 shadow-sm"
                  >
                    <p class="comment-text text-sm text-slate-600 leading-relaxed">
                      This is the second "child" comment. The comments in the row below this one are all direct replies to this specific comment, creating a deeper conversational branch. The line from this box will fork out to its children.
                    </p>
                    <div class="flex items-center justify-between mt-4">
                      <div class="flex items-center gap-3 text-slate-400">
                        <button
                          phx-click="vote"
                          phx-value-comment-id="child-2"
                          phx-value-vote="1"
                          class="hover:text-green-500"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="18"
                            height="18"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                          >
                            <path d="M7 11v4a1 1 0 0 0 1 1h3a1 1 0 0 0 1-1v-4a1 1 0 0 0-1-1H8a1 1 0 0 0-1 1z" />
                            <path d="M12 7.5a2.5 2.5 0 0 1 0 5" />
                            <path d="M17 8v8" />
                            <path d="M21 7.5a2.5 2.5 0 0 0-5 0v1a2.5 2.5 0 0 0 5 0" />
                          </svg>
                        </button>
                        <span class="font-semibold text-xs text-slate-500">72</span>
                        <button
                          phx-click="vote"
                          phx-value-comment-id="child-2"
                          phx-value-vote="-1"
                          class="hover:text-red-500"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="18"
                            height="18"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                          >
                            <path d="M7 13v-4a1 1 0 0 1 1-1h3a1 1 0 0 1 1 1v4a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1z" />
                            <path d="M12 16.5a2.5 2.5 0 0 0 0-5" />
                            <path d="M17 16V8" />
                            <path d="M21 16.5a2.5 2.5 0 0 1-5 0v-1a2.5 2.5 0 0 1 5 0" />
                          </svg>
                        </button>
                      </div>
                      <div class="flex items-center gap-2">
                        <button
                          phx-click="show_reply_form"
                          phx-value-comment-id="child-2"
                          class="px-3 py-1.5 text-xs font-semibold bg-slate-200 text-slate-700 rounded-md hover:bg-slate-300"
                        >
                          Reply
                        </button>
                      </div>
                    </div>
                  </div>
                  <div
                    id="child-comment-3"
                    class="comment-box flex-shrink-0 w-5/6 md:w-2/5 lg:w-[32%] bg-white border border-slate-200 rounded-lg p-5 shadow-sm"
                  >
                    <p class="comment-text text-sm text-slate-600 leading-relaxed">
                      This is the third "child" comment, another sibling in this row. It also replies directly to the mother comment. This demonstrates how multiple, parallel conversations can stem from a single point.
                    </p>
                    <div class="flex items-center justify-between mt-4">
                      <div class="flex items-center gap-3 text-slate-400">
                        <button
                          phx-click="vote"
                          phx-value-comment-id="child-3"
                          phx-value-vote="1"
                          class="hover:text-green-500"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="18"
                            height="18"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                          >
                            <path d="M7 11v4a1 1 0 0 0 1 1h3a1 1 0 0 0 1-1v-4a1 1 0 0 0-1-1H8a1 1 0 0 0-1 1z" />
                            <path d="M12 7.5a2.5 2.5 0 0 1 0 5" />
                            <path d="M17 8v8" />
                            <path d="M21 7.5a2.5 2.5 0 0 0-5 0v1a2.5 2.5 0 0 0 5 0" />
                          </svg>
                        </button>
                        <span class="font-semibold text-xs text-slate-500">55</span>
                        <button
                          phx-click="vote"
                          phx-value-comment-id="child-3"
                          phx-value-vote="-1"
                          class="hover:text-red-500"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="18"
                            height="18"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                          >
                            <path d="M7 13v-4a1 1 0 0 1 1-1h3a1 1 0 0 1 1 1v4a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1z" />
                            <path d="M12 16.5a2.5 2.5 0 0 0 0-5" />
                            <path d="M17 16V8" />
                            <path d="M21 16.5a2.5 2.5 0 0 1-5 0v-1a2.5 2.5 0 0 1 5 0" />
                          </svg>
                        </button>
                      </div>
                      <div class="flex items-center gap-2">
                        <button
                          phx-click="show_reply_form"
                          phx-value-comment-id="child-3"
                          class="px-3 py-1.5 text-xs font-semibold bg-slate-200 text-slate-700 rounded-md hover:bg-slate-300"
                        >
                          Reply
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex flex-col space-y-2">
                  <button
                    phx-click="scroll_row"
                    phx-value-row="row2"
                    phx-value-direction="left"
                    class="p-2 bg-white border rounded-full text-slate-500 hover:bg-slate-100"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      width="20"
                      height="20"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2.5"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    >
                      <path d="m15 18-6-6 6-6" />
                    </svg>
                  </button>
                  <button
                    phx-click="scroll_row"
                    phx-value-row="row2"
                    phx-value-direction="right"
                    class="p-2 bg-white border rounded-full text-slate-500 hover:bg-slate-100"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      width="20"
                      height="20"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2.5"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    >
                      <path d="m9 18 6-6-6-6" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
            
    <!-- SECTION: Bottom Row (Grandchild Comments) -->
            <div class="row-container">
              <div class="flex items-center space-x-2">
                <div id="row3" class="flex-1 flex gap-3 overflow-x-hidden no-scrollbar scroll-smooth">
                  <div
                    id="grandchild-comment-1"
                    class="comment-box flex-shrink-0 w-4/5 md:w-1/3 lg:w-[19%] bg-white border rounded-lg p-4 shadow-sm"
                  >
                    <p class="comment-text text-xs text-slate-600 leading-normal">
                      A "grandchild" comment. This is a reply to the middle comment in the second row, taking that specific branch of the conversation one level deeper.
                    </p>
                  </div>
                  <div
                    id="grandchild-comment-2"
                    class="comment-box flex-shrink-0 w-4/5 md:w-1/3 lg:w-[19%] bg-white border rounded-lg p-4 shadow-sm"
                  >
                    <p class="comment-text text-xs text-slate-600 leading-normal">
                      This is another reply to the same parent comment in the row above, making it a "sibling" to the other comments in this row.
                    </p>
                  </div>
                  <div
                    id="grandchild-comment-3"
                    class="comment-box flex-shrink-0 w-4/5 md:w-1/3 lg:w-[19%] bg-white border rounded-lg p-4 shadow-sm"
                  >
                    <p class="comment-text text-xs text-slate-600 leading-normal">
                      The smaller size of these boxes indicates they are for more granular, quick-fire responses at the lowest level of the visible hierarchy.
                    </p>
                  </div>
                  <div
                    id="grandchild-comment-4"
                    class="comment-box flex-shrink-0 w-4/5 md:w-1/3 lg:w-[19%] bg-white border rounded-lg p-4 shadow-sm"
                  >
                    <p class="comment-text text-xs text-slate-600 leading-normal">
                      Fourth grandchild comment, continuing the discussion from the parent comment in the second row.
                    </p>
                  </div>
                  <div
                    id="grandchild-comment-5"
                    class="comment-box flex-shrink-0 w-4/5 md:w-1/3 lg:w-[19%] bg-white border rounded-lg p-4 shadow-sm"
                  >
                    <p class="comment-text text-xs text-slate-600 leading-normal">
                      Fifth grandchild comment. The horizontal scroll implies that many more replies can exist at this level.
                    </p>
                  </div>
                </div>
                <div class="flex flex-col space-y-2">
                  <button
                    phx-click="scroll_row"
                    phx-value-row="row3"
                    phx-value-direction="left"
                    class="p-2 bg-white border rounded-full text-slate-500 hover:bg-slate-100"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      width="20"
                      height="20"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2.5"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    >
                      <path d="m15 18-6-6 6-6" />
                    </svg>
                  </button>
                  <button
                    phx-click="scroll_row"
                    phx-value-row="row3"
                    phx-value-direction="right"
                    class="p-2 bg-white border rounded-full text-slate-500 hover:bg-slate-100"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      width="20"
                      height="20"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2.5"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    >
                      <path d="m9 18 6-6-6-6" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </body>
    </html>
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
  def handle_event("scroll_row", %{"row" => row_id, "direction" => direction}, socket) do
    # This will trigger JavaScript to scroll the row
    {:noreply, push_event(socket, "scroll_row", %{row: row_id, direction: direction})}
  end

  @impl true
  def handle_event("show_reply_form", %{"comment-id" => comment_id}, socket) do
    if socket.assigns.current_user do
      # Use Comment alias. Keep api: Conversation here, as AshPhoenix.Form.for_create expects the API
      form =
        AshPhoenix.Form.for_create(Comment, :create,
          api: Conversation,
          params: %{parent_comment_id: comment_id}
        )

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
      case AshPhoenix.Form.submit(form,
             params: comment_params,
             actor: current_user,
             api: Conversation
           ) do
        # New comment successfully created!
        {:ok, _new_comment} ->
          # --- Start: Logic to dynamically update comments list ---

          # Re-fetch the entire conversation tree.
          # Use the comments_query defined in mount for consistency.
          # The API is already set within the query object stored in assigns.
          # Correct: Removed api: option here
          updated_comments = Ash.read!(socket.assigns.comments_query)

          socket =
            socket
            # Update the main comments assign
            |> assign(:comments, updated_comments)
            # Hide the form
            |> assign(:replying_to_id, nil)
            # Clear the form state
            |> assign(:reply_form, nil)
            # Show success message
            |> put_flash(:info, "Reply posted!")

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
    # Filter for root comments
    |> Ash.Query.do_filter(parent_comment_id: nil)
    |> Ash.Query.load([
      # Load the user for the current comment
      :user,
      # Load the vote score for the current comment
      :vote_score,
      # Specify what to load for child comments
      child_comments: [:user, :vote_score]
    ])
    # Correct: Set the domain on the query
    |> Ash.Query.set_domain(Stepvo.Conversation)
  end
end
