defmodule ArchethicPlayground.MockFunctions do
  @moduledoc false
  @behaviour Archethic.Contracts.Interpreter.Library.Common.Chain
  @behaviour Archethic.Contracts.Interpreter.Library.Common.Token

  @impl Archethic.Contracts.Interpreter.Library.Common.Chain
  def get_genesis_address(address) do
    Process.get("Chain.get_genesis_address_#{address}")
  end

  @impl Archethic.Contracts.Interpreter.Library.Common.Chain
  def get_first_transaction_address(address) do
    Process.get("Chain.get_first_transaction_address_#{address}")
  end

  @impl Archethic.Contracts.Interpreter.Library.Common.Chain
  def get_genesis_public_key(public_key) do
    Process.get("Chain.get_genesis_public_key_#{public_key}")
  end

  @impl Archethic.Contracts.Interpreter.Library.Common.Token
  def fetch_id_from_address(address) do
    Process.get("Token.fetch_id_from_address_#{address}")
  end
end
