defmodule StepvoWeb.LayoutView do
  use StepvoWeb, :html

  def render("root.html", assigns) do
    ~H"""
    <.flash_group flash={@flash} />
    <%= @inner_content %>
    """
  end
end
# This module is responsible for rendering the root layout of the application.
# It uses the `StepvoWeb` module to include common functionality and helpers.
# The `render/2` function defines the structure of the root layout, which includes
