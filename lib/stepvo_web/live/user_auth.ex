defmodule StepvoWeb.UserAuth do
  

  def on_mount(:default, _params, _session, socket) do
    # Fetch the current user from the session or other source
    current_user = get_current_user_from_session(socket)

    # Assign the current user to the socket
    {:cont, Phoenix.Component.assign(socket, :current_user, current_user)}
  end

  defp get_current_user_from_session(_socket) do
    # Replace this with your logic to fetch the user
    # For example, fetch from session or database
    nil
  end
end
