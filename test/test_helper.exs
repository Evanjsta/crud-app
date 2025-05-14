# test/test_helper.exs
ExUnit.start()

IO.puts("Starting :stepvo application for tests...")
Application.ensure_all_started(:stepvo)
IO.puts(":stepvo application started successfully.")

# ---> ADD THIS LINE <---
# Force compilation after app start, within test env context
Mix.Task.run("compile", ["--force", "--no-deps-check"]) # Force compile project code
IO.puts("Forced compile task run.")


Ecto.Adapters.SQL.Sandbox.mode(Stepvo.Repo, :manual)
IO.puts("Repo Sandbox mode set.")
