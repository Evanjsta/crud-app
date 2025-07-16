defmodule StepvoWeb.Layouts do
  # This will import all the necessary helpers
  use StepvoWeb, :html

  @moduledoc """
  Provides layout rendering for LiveViews and other components.
  """

  def live(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{assigns[:page_title] || "Stepvo"}</title>
        <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
        <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}>
        </script>
      </head>
      <body>
        {@inner_content}
      </body>
    </html>
    """
  end

  # Define root layout directly as a function component
  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" class="h-full bg-gray-50">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={get_csrf_token()} />
        <.live_title suffix=" · Stepvo">
          {assigns[:page_title] || "Stepvo"}
        </.live_title>
        <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
        <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}>
        </script>
      </head>
      <body class="h-full">
        <!-- Embed the inner content (usually the :app layout or controller content) -->
        {@inner_content}
      </body>
    </html>
    """
  end

  # Define app layout directly as a function component
  # (Used by LiveViews or controllers unless layout: false)
  def app(assigns) do
    ~H"""
    <main class="px-4 py-10 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl">
        <%!-- Optional: Add shared navigation/header here --%>
        <%!-- Example:
        <header class="mb-6 text-center">
          <h1 class="text-2xl font-bold">Stepvo</h1>
          <nav class="space-x-4">
            <.link href={~p"/"}>Home</.link>
            <.link href={~p"/conversation"}>Conversation</.link>
            <%# Add Login/Logout links later %>
          </nav>
        </header>
        --%>

        <%!-- The actual page/LiveView content renders here --%>
        {@inner_content}
      </div>
    </main>
    """
  end
end
