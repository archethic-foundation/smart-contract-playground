defmodule ArchethicPlaygroundWeb.EditorLive do
  @moduledoc false

  alias ArchethicPlayground.Mock
  alias ArchethicPlayground.Utils
  alias ArchethicPlayground.Transaction
  alias ArchethicPlayground.TriggerForm
  alias ArchethicPlaygroundWeb.ConsoleComponent
  alias ArchethicPlaygroundWeb.ContractComponent
  alias ArchethicPlaygroundWeb.DeployComponent
  alias ArchethicPlaygroundWeb.FunctionComponent
  alias ArchethicPlaygroundWeb.HeaderComponent
  alias ArchethicPlaygroundWeb.SidebarComponent
  alias ArchethicPlaygroundWeb.TriggerComponent
  alias Archethic.Contracts.Contract

  use ArchethicPlaygroundWeb, :live_view

  def mount(params, _opts, socket) do
    socket =
      socket
      |> assign(
        left_panel: nil,
        console_messages: [],
        selected_function: nil,
        function_args: nil,
        trigger: nil,
        mocks: [],
        right_panel: "contract",
        transaction_contract:
          Transaction.new(%{"type" => "contract"}) |> Ecto.Changeset.apply_changes()
      )

    {:ok, socket}
  end

  def handle_params(%{"state" => base64}, uri, socket = %{assigns: state}) do
    %{
      code: code,
      left_panel: left_panel,
      right_panel: right_panel,
      console_messages: console_messages,
      selected_function: selected_function,
      function_args: function_args,
      trigger: trigger,
      mocks: mocks,
      contract: %{
        type: contract_type,
        content: contract_content,
        timestamp: contract_timestamp,
        address: contract_address,
        recipients: contract_recipients,
        uco_transfers: contract_uco_transfers,
        token_transfers: contract_token_transfers,
        ownerships: contract_ownerships
      }
    } =
      with {:ok, json} <- Base.decode64(base64),
           {:ok, new_state} <- Jason.decode(json, keys: :atoms!) do
        new_state
      else
        _ ->
          extract_assign_values(state)
      end

    tx_contract =
      Transaction.new(%{
        "address" => contract_address,
        "type" => contract_type,
        "code" => code,
        "content" => contract_content,
        "uco_transfers" => contract_uco_transfers,
        "token_transfers" => contract_token_transfers,
        "recipients" => contract_recipients
      })
      |> Ecto.Changeset.apply_changes()

    {triggers, functions} =
      case ArchethicPlayground.parse(tx_contract) do
        {:ok, contract} ->
          {get_triggers(contract), get_public_functions(contract)}

        {:error, message} ->
          {[], []}
      end

    trigger_form =
      if trigger do
        TriggerForm.new(trigger) |> Ecto.Changeset.apply_changes()
      else
        nil
      end

    new_socket =
      socket
      |> assign(
        left_panel: left_panel,
        code: code,
        right_panel: right_panel,
        console_messages:
          Enum.map(console_messages, fn [date, class, message] ->
            {:ok, date, _} = DateTime.from_iso8601(date)
            [date, class, message]
          end),
        triggers: triggers,
        functions: functions,
        transaction_contract: tx_contract,
        selected_function: selected_function,
        function_args: function_args,
        trigger: trigger_form,
        mocks: Enum.map(mocks, &Mock.cast/1)
      )
      |> push_event("set-code", %{"code" => code})

    {:noreply, new_socket}
  end

  def handle_params(_, _uri, socket) do
    code = default_code()
    # we define a random address so we can prefill the trigger transaction recipients
    random_address = Utils.Address.random() |> Base.encode16()

    state = %{
      left_panel: nil,
      selected_function: nil,
      code: code,
      right_panel: "contract",
      console_messages: [],
      triggers: [],
      functions: [],
      mocks: [],
      transaction_contract:
        Transaction.new(%{
          "address" => random_address,
          "type" => "contract",
          "code" => code
        })
        |> Ecto.Changeset.apply_changes()
    }

    socket =
      socket
      |> assign(state)
      |> push_event("set-code", %{"code" => state.code})

    # do a first parse in order to fill the triggers
    send(self(), {:parse, state.code})

    {:noreply, socket}
  end

  def handle_event("toggle_panel", %{"panel" => panel, "side" => side}, socket) do
    {left_panel, right_panel} =
      do_toggle_panels({side, panel}, {socket.assigns.left_panel, socket.assigns.right_panel})

    state64 =
      socket.assigns
      |> Map.put(:left_panel, left_panel)
      |> Map.put(:right_panel, right_panel)
      |> get_state_url()

    socket =
      socket
      |> push_event("resize-editor", %{})
      |> push_patch(to: "/#{state64}", replace: true)

    {:noreply, socket}
  end

  def handle_event("parse", %{"code" => code}, socket) do
    send(self(), {:parse, code})
    {:noreply, socket}
  end

  def handle_info({:parse, code}, socket = %{assigns: state}) do
    transaction_contract = %Transaction{socket.assigns.transaction_contract | code: code}

    {triggers, functions, error_message} =
      case ArchethicPlayground.parse(transaction_contract) do
        {:ok, contract} ->
          {get_triggers(contract), get_public_functions(contract), nil}

        {:error, message} ->
          {[], [], message}
      end

    # maybe it'd be good to store the contract as well

    console_messages =
      if error_message do
        [console_message("error", error_message)]
      else
        []
      end

    new_state =
      state
      |> Map.put(:triggers, triggers)
      |> Map.put(:functions, functions)
      |> Map.put(:transaction_contract, transaction_contract)
      |> Map.put(:code, code)
      |> Map.put(:console_messages, console_messages)

    state64 =
      new_state
      |> extract_assign_values()
      |> Jason.encode!()
      |> Base.encode64()

    if code != state.code do
      {:noreply, push_patch(socket, to: "/#{state64}", replace: true)}
    else
      {:noreply,
       assign(socket,
         triggers: triggers,
         functions: functions,
         transaction_contract: transaction_contract
       )}
    end
  end

  def handle_info(:reset_transaction_contract, socket = %{assigns: state = %{code: code}}) do
    transaction_contract =
      Transaction.new(%{"type" => "contract", "code" => code})
      |> Ecto.Changeset.apply_changes()

    state64 =
      socket.assigns
      |> Map.put(:contract, %{
        type: "contract",
        content: transaction_contract.content,
        code: code,
        timestamp: transaction_contract.validation_timestamp,
        address: transaction_contract.address,
        recipients: transaction_contract.recipients,
        uco_transfers: transaction_contract.uco_transfers,
        token_transfers: transaction_contract.token_transfers,
        ownerships: transaction_contract.ownerships
      })
      |> get_state_url()

    {:noreply, push_patch(socket, to: "/#{state64}", replace: true)}
  end

  def handle_info({:set_transaction_contract, transaction}, socket) do
    state64 =
      socket.assigns
      |> Map.put(:contract, %{
        type: transaction.type,
        content: transaction.content,
        timestamp: transaction.validation_timestamp,
        address: transaction.address,
        recipients: transaction.recipients,
        uco_transfers: transaction.uco_transfers,
        token_transfers: transaction.token_transfers,
        ownerships: transaction.ownerships
      })
      |> get_state_url()

    {:noreply, push_patch(socket, to: "/#{state64}", replace: true)}
  end

  def handle_info({:execute_function, function_name, args_values, args_names}, socket) do
    execution_message =
      case ArchethicPlayground.execute_function(
             socket.assigns.transaction_contract,
             function_name,
             args_values
           ) do
        {:ok, result} ->
          console_message("success", "Result: #{inspect(result)}")

        {:error, :function_failure} ->
          console_message("error", "Function failed")

        {:error, :timeout} ->
          console_message("error", "Function timed-out")
      end

    console_messages = [
      console_message("info", "Executing function: #{function_name}/#{length(args_values)}"),
      execution_message
    ]

    function_name_str = "#{function_name}(#{Enum.join(args_names, ",")})"

    state64 =
      socket.assigns
      |> Map.put(:selected_function, function_name_str)
      |> Map.put(:function_args, args_values)
      |> Map.put(:console_messages, console_messages)
      |> get_state_url()

    {:noreply, push_patch(socket, to: "/#{state64}", replace: true)}
  end

  def handle_info(:clear_selected_function, socket) do
    state64 =
      socket.assigns
      |> Map.put(:selected_function, nil)
      |> Map.put(:function_args, nil)
      |> get_state_url()

    {:noreply, push_patch(socket, to: "/#{state64}", replace: true)}
  end

  def handle_info({:execute_trigger, trigger_form, mocks, replace_contract?}, socket) do
    {socket, execution_message} =
      case ArchethicPlayground.execute(
             socket.assigns.transaction_contract,
             trigger_form,
             mocks
           ) do
        {:ok, nil} ->
          {socket, console_message("success", "No resulting transaction")}

        {:ok, tx} ->
          tx_output =
            Transaction.to_short_map(tx,
              filter_code: tx.code == socket.assigns.transaction_contract.code
            )

          if replace_contract? do
            # hack:
            # we give the transaction the same address as previous so we can chain without having to
            # update the recipients on the trigger form
            tx = %Transaction{tx | address: socket.assigns.transaction_contract.address}

            new_socket =
              socket
              |> assign(transaction_contract: tx)
              |> push_event("set-code", %{"code" => tx.code})

            {new_socket, console_message("success", tx_output)}
          else
            {socket, console_message("success", tx_output)}
          end

        {:error, :invalid_transaction_constraints} ->
          {socket, console_message("error", "Contract's condition 'transaction' failed")}

        {:error, :invalid_inherit_constraints} ->
          {socket, console_message("error", "Contract's condition 'inherit' failed")}

        {:error, :invalid_oracle_constraints} ->
          {socket, console_message("error", "Contract's condition 'oracle' failed")}

        {:error, :invalid_triggers_execution} ->
          {socket, console_message("error", "Trigger is incorrect")}

        {:error, :contract_failure} ->
          {socket, console_message("error", "Contract's execution failed")}

        {:error, {:recipient_argument_is_not_json, value}} ->
          {socket, console_message("error", "A recipient's argument is not valid JSON: #{value}")}

        {:error, message} when is_binary(message) ->
          {socket, console_message("error", message)}
      end

    console_messages = [
      console_message("info", "Executing trigger: #{trigger_form.trigger}"),
      execution_message
    ]

    state64 =
      socket.assigns
      |> Map.put(:console_messages, console_messages)
      |> Map.put(:trigger, %{
        trigger: trigger_form.trigger,
        recipient: trigger_form.recipient,
        transaction:
          Map.take(trigger_form.transaction, [
            :type,
            :content,
            :code,
            :validation_timestamp,
            :address,
            :recipients,
            :uco_transfers,
            :token_transfers,
            :ownership
          ])
      })
      |> Map.put(:mocks, mocks)
      |> get_state_url()

    {:noreply, push_patch(socket, to: "/#{state64}", replace: true)}
  end

  #              _            _
  #   _ __  _ __(___   ____ _| |_ ___
  #  | '_ \| '__| \ \ / / _` | __/ _ \
  #  | |_) | |  | |\ V | (_| | ||  __/
  #  | .__/|_|  |_| \_/ \__,_|\__\___|
  #  |_|

  defp get_triggers(%Contract{triggers: triggers}) do
    triggers
    |> Enum.map(fn
      {{:transaction, action, arity}, %{args: args_names}}
      when not is_nil(action) and not is_nil(arity) ->
        # we replace the arity by args_names to be able to put labels on the inputs
        {:transaction, action, args_names}

      {trigger_key, _} ->
        trigger_key
    end)
    |> Enum.map(&TriggerForm.serialize_trigger/1)
  end

  defp get_public_functions(%Contract{functions: functions}) do
    functions
    |> Enum.reduce([], fn
      {{name, _arity}, %{args: args_names, visibility: :public}}, acc ->
        [{name, args_names} | acc]

      _, acc ->
        acc
    end)
  end

  defp do_toggle_panels({"left", panel}, {current_left_panel, current_right_panel}) do
    left_panel = if panel == current_left_panel, do: nil, else: panel
    {left_panel, current_right_panel}
  end

  defp do_toggle_panels({"right", panel}, {current_left_panel, current_right_panel}) do
    right_panel = if panel == current_right_panel, do: nil, else: panel
    {current_left_panel, right_panel}
  end

  defp default_code(),
    do: ~S"""
    @version 1

    condition triggered_by: transaction, as: []
    actions triggered_by: transaction do
      Contract.set_content "Hello world!"
    end
    """

  defp extract_assign_values(%{
         code: code,
         left_panel: left_panel,
         right_panel: right_panel,
         selected_function: selected_function,
         function_args: function_args,
         console_messages: console_messages,
         trigger: trigger_form,
         mocks: mocks,
         transaction_contract: %{
           type: contract_type,
           content: contract_content,
           validation_timestamp: contract_timestamp,
           address: contract_address,
           recipients: contract_recipients,
           uco_transfers: contract_uco_transfers,
           token_transfers: contract_token_transfers,
           ownerships: contract_ownerships
         }
       }) do
    %{
      code: code,
      left_panel: left_panel,
      right_panel: right_panel,
      console_messages: console_messages,
      selected_function: selected_function,
      function_args: function_args,
      trigger: trigger_form,
      mocks: mocks,
      contract: %{
        type: contract_type,
        content: contract_content,
        timestamp: contract_timestamp,
        address: contract_address,
        recipients: contract_recipients,
        uco_transfers: contract_uco_transfers,
        token_transfers: contract_token_transfers,
        ownerships: contract_ownerships
      }
    }
  end

  defp console_message(message_type, message)
       when message_type in ["info", "success", "warning", "error"],
       do: [DateTime.utc_now(), message_type, message]

  defp get_state_url(assigns) do
    assigns
    |> extract_assign_values()
    |> Jason.encode!()
    |> Base.encode64()
  end
end
