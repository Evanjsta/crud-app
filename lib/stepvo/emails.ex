defmodule Stepvo.Emails do

  import Swoosh.Email

  # Alias your mailer module
  alias Stepvo.Mailer

  def deliver_magic_link(user_or_email, url) do
    # Extract the email address
    email_address =
      case user_or_email do
        %_{email: address} -> address # User struct
        address when is_binary(address) -> address # Email string
        _ -> nil
      end


    if email_address && url do

      email =
        new()
        |> to(email_address)
        |> from({"Stepvo", "noreply@yourdomain.com"}) # Replace with your desired From address
        |> subject("Sign in to Stepvo")
        |> text_body(
          """
          Hi #{email_address},

          Click the link below to sign in to Stepvo:
          #{url}

          If you didn't request this, please ignore this email.
          """
        )
        |> html_body(
          """
          <html>
            <body>
              <p>Hi #{email_address},</p>
              <p>Click the link below to sign in to Stepvo:</p>
              <p><a href="#{url}">Sign In Now</a></p>
              <p>If you didn't request this, please ignore this email.</p>
            </body>
          </html>
          """
        )

      # Deliver the email using your Mailer module
      case Mailer.deliver(email) do
        {:ok, _metadata} -> # Match the tuple {:ok, ...}
    IO.puts("Magic link email sent successfully to #{email_address}")
    :ok # Still return :ok from the function on success

  {:error, reason} ->
    IO.inspect(reason, label: "Error sending magic link email")
    {:error, reason}
      end
    else
      {:error, "Missing email address or URL for magic link delivery"}
    end
  end
end
