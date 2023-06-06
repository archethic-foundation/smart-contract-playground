defmodule ArchethicPlayground do
  @moduledoc """
  Main module to run the functionality needed
  """
  alias Archethic.Contracts
  alias Archethic.Contracts.Contract
  alias Archethic.Contracts.ContractConstants, as: Constants
  alias Archethic.Contracts.Interpreter

  alias Archethic.TransactionChain.Transaction
  alias Archethic.TransactionChain.TransactionData

  def parse(code) do
    Contracts.from_transaction(%Transaction{
      type: :contract,
      address: <<0::272>>,
      data: %TransactionData{
        code: code
      }
    })
  end
end
