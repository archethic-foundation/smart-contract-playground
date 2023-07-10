defmodule ArchethicPlayground.Utils.Struct do
  def deep_struct_to_map(var) do
    cond do
      is_struct(var) ->
        Map.from_struct(var)
        |> Enum.map(fn {key, value} ->
          {key, deep_struct_to_map(value)}
        end)
        |> Enum.into(%{})

      is_list(var) ->
        Enum.map(var, &deep_struct_to_map/1)

      true ->
        var
    end
  end
end
