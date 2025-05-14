defmodule Stepvo.Conversation.Senders.SendMagicLink do
  @moduledoc """
  Sends the magic sign-in link email.
  """
  # Use the Sender behaviour provided by AshAuthentication
  use AshAuthentication.Sender
  # Import your web routes if using Phoenix for URL generation
  # If not using Phoenix, you'll need to construct the URL manually
  # based on your frontend/API setup.
  # Assuming a Phoenix setup for this example:
  use StepvoWeb, :verified_routes # Replace StepvoWeb with your actual Web module name

  # Define the required send/3 callback
  @impl AshAuthentication.Sender
  def send(user_or_email, token, _context) do
    # user_or_email will be:
    # - a %Stepvo.Conversation.User{} struct if the user already exists
    # - just the email string if registration is enabled and the user doesn't exist yet

    # 1. Construct the verification URL
    #    Uses the named route helpers from StepvoWeb (adjust path as needed)
    #    This assumes you'll have a route like /auth/user/magic_link?token=...
    #    that AshAuthentication.Plug (or similar) will handle.
    verification_url = url(~p"/auth/user/magic?token=#{token}")

    # 2. Call a separate function/module responsible for email delivery
    #    Pass the user/email and the generated URL to it.
    #    This keeps email sending logic separate from the sender callback.
    Stepvo.Emails.deliver_magic_link(user_or_email, verification_url)

    # Return :ok to indicate success (or {:error, reason} on failure)
    :ok
  end
end
