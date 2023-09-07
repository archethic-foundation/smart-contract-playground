defmodule ArchethicPlaygroundWeb.FunctionComponent do
  @moduledoc false

  use ArchethicPlaygroundWeb, :live_component

  alias ArchethicPlayground.KeyValue

  def id(), do: "function_component"

  def mount(socket) do
    {:ok, assign(socket, form: clean_form())}
  end

  def update(assigns = %{functions: []}, socket) do
    # we reset the state when there is no functions anymore
    # might happen if the code is modified and is invalid
    {:ok,
     socket
     |> assign(assigns)
     |> assign(form: clean_form())}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event(
        "on-form-change",
        %{"_target" => ["function"], "function" => ""},
        socket
      ) do
    # this is the prompt "-- Choose a function --" option
    {:noreply, assign(socket, form: clean_form())}
  end

  def handle_event(
        "on-form-change",
        %{"_target" => ["function"], "function" => function_str},
        socket
      ) do
    {function, args_names} = deserialize_function(function_str)

    {:noreply,
     assign(socket,
       form:
         to_form(%{
           "function" => function,
           "args" => Enum.map(args_names, &%KeyValue{key: &1, value: ""})
         })
     )}
  end

  def handle_event("on-form-change", _params, socket) do
    # we should update the state here as well so we could
    # use the socket.assigns in the on-form-submit instead of
    # casting it over there
    {:noreply, socket}
  end

  def handle_event("on-form-submit", params = %{"function" => function_str}, socket) do
    args_values =
      case Map.get(params, "args") do
        nil ->
          []

        args ->
          # here args is %{"0" => %{"value" => "a"}, "1" => %{"value" => "b"}},
          args
          |> Map.values()
          |> Enum.flat_map(&Map.values/1)
          |> Enum.map(fn value ->
            # if it's json, we decode it
            # if it isn't we just treat it as a string
            case Jason.decode(value) do
              {:ok, term} ->
                term

              {:error, _} ->
                value
            end
          end)
      end

    {function, _args_names} = deserialize_function(function_str)

    send(
      self(),
      {:execute_function, function, args_values}
    )

    {:noreply, socket}
  end

  defp serialize_function({name, args_names}),
    do: "#{name}(#{Enum.join(args_names, ",")})"

  def deserialize_function(str) do
    [function, joined_args] = Regex.run(~r/(\w+)\(([\w, ]*)\)/, str, capture: :all_but_first)

    args_names =
      case joined_args do
        "" ->
          []

        _ ->
          joined_args |> String.split(",") |> Enum.map(&String.trim/1)
      end

    {function, args_names}
  end

  defp clean_form() do
    to_form(%{
      "function" => "",
      "args" => []
    })
  end
end
