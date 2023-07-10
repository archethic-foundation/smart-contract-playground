defmodule ArchethicPlayground.MockFunctions do
  @moduledoc false
  @behaviour Archethic.Contracts.Interpreter.Library.Common.Chain
  @behaviour Archethic.Contracts.Interpreter.Library.Common.Token

  alias ArchethicPlayground.TriggerForm.Mock

  def prepare_mocks(mocks) do
    remove_existing_mocks()
    Enum.each(mocks, &add_mock/1)
  end

  @impl Archethic.Contracts.Interpreter.Library.Common.Chain
  def get_genesis_address(address) do
    case Process.get("Chain.get_genesis_address/1_#{address}") do
      nil ->
        log_missing_mock_to_playground_console("Chain.get_genesis_address/1", address)
        raise "missing_mock"

      value ->
        value
    end
  end

  @impl Archethic.Contracts.Interpreter.Library.Common.Chain
  def get_first_transaction_address(address) do
    case Process.get("Chain.get_first_transaction_address/1_#{address}") do
      nil ->
        log_missing_mock_to_playground_console("Chain.get_first_transaction_address/1", address)
        raise "missing_mock"

      value ->
        value
    end
  end

  @impl Archethic.Contracts.Interpreter.Library.Common.Chain
  def get_genesis_public_key(public_key) do
    case Process.get("Chain.get_genesis_public_key/1_#{public_key}") do
      nil ->
        log_missing_mock_to_playground_console("Chain.get_genesis_public_key/1", public_key)
        raise "missing_mock"

      value ->
        value
    end
  end

  @impl Archethic.Contracts.Interpreter.Library.Common.Token
  def fetch_id_from_address(address) do
    case Process.get("Chain.fetch_id_from_address/1_#{address}") do
      nil ->
        log_missing_mock_to_playground_console("Chain.fetch_id_from_address/1", address)
        raise "missing_mock"

      value ->
        value
    end
  end

  defp add_mock(mock = %Mock{}) do
    Process.put("#{mock.function}_#{mock.input}", mock.output)
  end

  defp remove_existing_mocks() do
    Process.get_keys()
    |> Enum.filter(&is_binary/1)
    |> Enum.each(&Process.delete/1)
  end

  defp log_missing_mock_to_playground_console(function, input) do
    send(self(), {:console, :error, "Missing mock #{function} for input value: #{input}"})
  end
end
