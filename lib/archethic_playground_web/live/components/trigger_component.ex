defmodule ArchethicPlaygroundWeb.TriggerComponent do
  @moduledoc false

  use ArchethicPlaygroundWeb, :live_component

  alias Archethic.Contracts
  alias Archethic.Contracts.Contract
  alias Archethic.TransactionChain.Transaction
  alias ArchethicPlaygroundWeb.CreateTransactionComponent

  def render(assigns) do
    ~H"""
      <div class={if @is_show_trigger == true, do: "flex flex-col h-4/4 py-2 min-w-[350px]", else: "hidden" }>
        <h2 class="text-lg font-medium text-gray-400 ml-4">Select a trigger</h2>
        <div class="relative mt-2 flex-1 px-2 sm:px-2">
            <div class="absolute inset-0 px-2 sm:px-2">
                <div class="h-full border-2 border border-gray-500 bg-black text-gray-200 p-4 overflow-y-auto">
                    <div class="block">
                        <.form :let={f} for={%{}} as={:form} phx-submit="execute_trigger" phx-change="update_form" phx-target={@myself} class="w-full max-w-lg">
                            <div class="flex flex-wrap -mx-3 mb-6">
                            <div class="w-full px-3">
                                <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="triggers">
                                Select the action you want to trigger
                                </label>
                                <%= select f, :trigger, @triggers, value: @selected_trigger, id: "triggers", prompt: "Select a trigger", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
                            </div>

                            <%= if @display_oracle_form do %>
                                <div class="w-full px-3">
                                <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="oracle-content">
                                    Oracle content
                                </label>
                                <%= text_input f, :oracle_content, id: "oracle-content", required: true, class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500"  %>
                                </div>
                            <% end %>
                            </div>
                            <div class="mt-5">
                            MOCK FUNCTIONS
                              <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="triggers">
                                Select the function you want to mock
                              </label>
                              <%= select f, :new_mock_function, @mock_functions, value: @new_mock_function, id: "mock_functions", prompt: "Select a function to mock", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
                              <%= if @new_mock_function != "Time.now" do %>
                                <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="mock-input">
                                  Input
                                </label>
                                <%= text_input f, :new_mock_input, value: @new_mock_input, id: "mock-input", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500"  %>
                              <% end %>
                              <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="mock-output">
                                Output
                              </label>
                              <%= text_input f, :new_mock_output, value: @new_mock_output, id: "mock-output", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500"  %>
                              <div class="mt-5">
                                <a phx-click="add_mock_function" phx-target={@myself} class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline" href="#">
                                  Add
                                </a>
                              </div>
                              <div class="mt-5">
                              <%= for mock_function <- @configured_mock_functions do %>
                                <div class="border border-gray-200 p-4 my-5">
                                  <div><span class="font-bold">Name:</span> <%= mock_function.function_name %></div>
                                  <%= if mock_function.function_name != "Time.now" do %>
                                    <div class="mb-2">
                                      <span class="font-bold">Input:</span>
                                      <span title={mock_function.input}><%= truncate_string(mock_function.input) %></span>
                                    </div>
                                  <% end %>
                                  <div class="mb-2">
                                    <span class="font-bold">Output:</span>
                                    <span title={mock_function.output}><%= truncate_string(mock_function.output) %></span>
                                  </div>
                                  <div>
                                    <a phx-click="remove_mock_function"
                                      phx-value-function_name={mock_function.function_name}
                                      phx-value-input={mock_function.input}
                                      phx-value-output={mock_function.output}
                                      phx-target={@myself}
                                      class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
                                      href="#">
                                      Delete
                                    </a>
                                  </div>
                                </div>
                              <% end %>
                              </div>
                            </div>
                        </.form>
                        <%= if @display_transaction_form do %>
                          <.live_component module={CreateTransactionComponent} id="create-transaction-trigger" module_to_update={__MODULE__} id_to_update="trigger_component" smart_contract_code={@smart_contract_code} aes_key={@aes_key} display_validation_timestamp_input={true} />
                        <% end %>
                        <div class="mt-5">
                            <button phx-click="execute_trigger" disabled={@selected_trigger == ""} phx-target={@myself} class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline" href="#">
                              Trigger
                            </button>
                          </div>
                    </div>
                </div>
            </div>
        </div>
      </div>
    """
  end

  def mount(socket) do
    socket =
      socket
      |> assign(:display_transaction_form, false)
      |> assign(:display_oracle_form, false)
      |> assign(:selected_trigger, "")
      |> assign(:transaction, nil)
      |> assign(:aes_key, :crypto.strong_rand_bytes(32))
      |> assign(:mock_functions, [
        "Chain.get_genesis_address",
        "Chain.get_first_transaction_address",
        "Chain.get_genesis_public_key",
        "Time.now",
        "Token.fetch_id_from_address"
      ])
      |> assign(:new_mock_function, "")
      |> assign(:new_mock_input, "")
      |> assign(:new_mock_output, "")
      |> assign(:configured_mock_functions, [])

    {:ok, socket}
  end

  def handle_event("update_form", params, socket) do
    trigger_form = params["form"]["trigger"]
    new_mock_function = params["form"]["new_mock_function"]
    new_mock_input = params["form"]["new_mock_input"]
    new_mock_output = params["form"]["new_mock_output"]
    display_transaction_form = trigger_form == "transaction"
    display_oracle_form = trigger_form == "oracle"

    socket =
      socket
      |> assign(:display_transaction_form, display_transaction_form)
      |> assign(:display_oracle_form, display_oracle_form)
      |> assign(:selected_trigger, trigger_form)
      |> assign(:new_mock_function, new_mock_function)
      |> assign(:new_mock_input, new_mock_input)
      |> assign(:new_mock_output, new_mock_output)

    {:noreply, socket}
  end

  def handle_event("add_mock_function", _, socket) do
    new_mock_function = socket.assigns.new_mock_function
    new_mock_input = socket.assigns.new_mock_input
    new_mock_output = socket.assigns.new_mock_output

    if new_mock_function != "" and new_mock_input != "" and new_mock_output != "" do
      add_mock_function(new_mock_function, new_mock_input, new_mock_output)

      socket =
        socket
        |> assign(:new_mock_function, "")
        |> assign(:new_mock_input, "")
        |> assign(:new_mock_output, "")
        |> assign(
          :configured_mock_functions,
          socket.assigns.configured_mock_functions ++
            [%{function_name: new_mock_function, input: new_mock_input, output: new_mock_output}]
        )

      {:noreply, socket}
    else
      send(self(), {:console, :clear})
      send(self(), {:console, %{"error" => "Please fill-in the mock function form"}})
      {:noreply, socket}
    end
  end

  def handle_event("remove_mock_function", params, socket) do
    function_name = params["function_name"]
    input = params["input"]
    output = params["output"]

    socket =
      socket
      |> assign(
        :configured_mock_functions,
        socket.assigns.configured_mock_functions
        |> Enum.reject(fn mock_function ->
          mock_function.function_name == function_name and mock_function.input == input and
            mock_function.output == output
        end)
      )

    remove_mock_function(function_name, input)
    {:noreply, socket}
  end

  def handle_event("execute_trigger", _, socket) do
    trigger =
      case socket.assigns.selected_trigger do
        "oracle" ->
          :oracle

        "transaction" ->
          :transaction

        key_with_param ->
          key_with_param
          |> parse_key_with_param()
      end

    handle_trigger(trigger, socket.assigns.transaction, socket)
  end

  defp parse_key_with_param(key_with_param) do
    [key | rest] = String.split(key_with_param, ":")

    case key do
      "interval" -> {:interval, List.first(rest)}
      "datetime" -> {:datetime, parse_datetime(List.first(rest))}
    end
  end

  defp parse_datetime(value) do
    {parsed_value, _} = Integer.parse(value)
    DateTime.from_unix!(parsed_value)
  end

  defp handle_trigger(:transaction, nil, socket) do
    send(self(), {:console, :clear})
    send(self(), {:console, %{"error" => "Please fill-in the transaction form"}})
    {:noreply, socket}
  end

  defp handle_trigger(trigger, transaction, socket) do
    execute_contract(
      trigger,
      socket.assigns.interpreted_contract,
      transaction,
      socket.assigns.configured_mock_functions
    )

    {:noreply, socket}
  end

  def update(%{transaction: transaction}, socket) do
    socket = assign(socket, transaction: transaction)
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  defp execute_contract(trigger, contract, maybe_tx, configured_mock_functions) do
    send(self(), {:console, :clear})
    send(self(), {:console, "Executing contract trigger: #{inspect(trigger)}"})

    datetime = get_time_now(configured_mock_functions)

    with :ok <- check_valid_precondition(trigger, contract, maybe_tx, datetime),
         {:ok, tx_or_nil} <-
           Contracts.execute_trigger(trigger, contract, maybe_tx, time_now: datetime),
         :ok <- check_valid_postcondition(contract, tx_or_nil, datetime) do
      send(self(), {:console, %{"success" => tx_or_nil}})
    else
      {:error, reason} ->
        send(self(), {:console, %{"error" => reason}})
    end
  end

  defp get_time_now(configured_mock_functions) do
    date_time_now =
      Enum.find(configured_mock_functions, fn %{function_name: function_name} ->
        function_name == "Time.now"
      end)

    case date_time_now do
      nil ->
        DateTime.utc_now()

      _ ->
        DateTime.from_unix!(String.to_integer(date_time_now.output))
    end
  end

  defp check_valid_precondition(
         :oracle,
         contract = %Contract{},
         tx = %Transaction{},
         datetime
       ) do
    if Contracts.valid_condition?(:oracle, contract, tx, datetime) do
      :ok
    else
      {:error, :invalid_oracle_constraints}
    end
  end

  defp check_valid_precondition(
         :transaction,
         contract = %Contract{},
         tx = %Transaction{},
         datetime
       ) do
    if Contracts.valid_condition?(:transaction, contract, tx, datetime) do
      :ok
    else
      {:error, :invalid_transaction_constraints}
    end
  end

  defp check_valid_precondition(_, _, _, _), do: :ok

  ##########
  defp check_valid_postcondition(
         contract = %Contract{},
         next_tx = %Transaction{},
         datetime
       ) do
    if Contracts.valid_condition?(:inherit, contract, next_tx, datetime) do
      :ok
    else
      {:error, :invalid_inherit_constraints}
    end
  end

  defp check_valid_postcondition(_, _, _), do: :ok

  defp add_mock_function(function_name, input, output) do
    get_mock_key_name(function_name, input) |> Process.put(output)
  end

  defp remove_mock_function(function_name, input) do
    get_mock_key_name(function_name, input) |> Process.delete()
  end

  defp get_mock_key_name(function_name, input) do
    "#{function_name}_#{input}"
  end

  defp truncate_string(""), do: ""

  defp truncate_string(s) when is_binary(s) do
    if String.length(s) > 15 do
      String.slice(s, 0..15) <> "..."
    else
      s
    end
  end

  defp truncate_string(s), do: s
end
