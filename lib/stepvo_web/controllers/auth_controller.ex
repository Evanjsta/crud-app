defmodule StepvoWeb.AuthController do
  use StepvoWeb, :controller
  use AshAuthentication.Phoenix.Controller

  @impl AshAuthentication.Phoenix.Controller
  def success(conn, _activity, user, _token) do
    return_to = get_session(conn, :return_to) || "/"

    conn
    |> delete_session(:return_to)
    |> store_in_session(user)
    |> assign(:current_user, user)
    |> redirect(to: return_to)
  end

  @impl AshAuthentication.Phoenix.Controller
  def failure(conn, _activity, _reason) do
    conn
    |> put_flash(:error, "Authentication failed.")
    |> redirect(to: "/")
  end

  @impl AshAuthentication.Phoenix.Controller
  def sign_out(conn, _params) do
    return_to = get_session(conn, :return_to) || "/"

    conn
    |> clear_session()
    |> redirect(to: return_to)
  end

  # Add the magic/2 action
  def magic(conn, %{"token" => token}) do
    case StepvoAuth.User.verify_magic_link_token(token) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> store_in_session(user)
        |> redirect(to: "/")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid or expired magic link.")
        |> redirect(to: "/")
    end
  end
end
