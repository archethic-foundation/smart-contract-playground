defmodule ArchethicPlayground.Utils.Date do
  @moduledoc """
  Example of browser date: "2023-07-14T21:41"
  Because it is binded to a form, we need to keep it as is
  And we do the cast to datetime only when necessary
  """
  def browser_timestamp_to_datetime(nil), do: nil

  def browser_timestamp_to_datetime(timestamp) do
    case DateTime.from_iso8601(timestamp <> ":00Z") do
      {:ok, datetime, _} ->
        datetime
    end
  end

  def datetime_to_browser_timestamp(nil), do: nil

  def datetime_to_browser_timestamp(datetime) do
    str =
      datetime
      |> DateTime.truncate(:second)
      |> DateTime.to_iso8601(:extended, 0)

    # removes the last 4 characters ":00Z"
    String.slice(str, 0..(String.length(str) - 5))
  end
end
