defmodule ArchethicPlayground do
  @moduledoc """
  Main module to run the functionality needed
  """
  alias Archethic.Contracts.Contract
  alias Archethic.Contracts.ContractConstants, as: Constants
  alias Archethic.Contracts.Interpreter

  alias Archethic.TransactionChain.Transaction
  alias Archethic.TransactionChain.TransactionData

  def interpret(code) do
    case Interpreter.parse(code) do
      {:ok, contract} ->
        # the contract must have the transaction in the constants for it to work
        # since there is no transaction for the contract yet, we have to fake it
        contract_tx = %Transaction{
          type: :contract,
          address: <<0::272>>,
          data: %TransactionData{}
        }

        {:ok,
         %Contract{
           contract
           | constants: %Constants{contract: Constants.from_transaction(contract_tx)}
         }}

      {:error, reason} ->
        {:error, reason}
    end

    # code
  end
end
