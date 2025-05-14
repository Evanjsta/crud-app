defmodule Stepvo.Repo do
  use Ecto.Repo,
    otp_app: :stepvo,
    adapter: Ecto.Adapters.Postgres

  def installed_extensions do
    ["ash-functions"]
  end
end
