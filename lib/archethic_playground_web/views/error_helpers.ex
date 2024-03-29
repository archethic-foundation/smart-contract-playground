defmodule ArchethicPlaygroundWeb.ErrorHelpers do
  @moduledoc false

  use Phoenix.HTML

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn {error, _} ->
      content_tag(:span, error,
        class: "invalid-feedback",
        phx_feedback_for: input_id(form, field)
      )
    end)
  end
end
