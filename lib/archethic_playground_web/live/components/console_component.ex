defmodule ArchethicPlaygroundWeb.ConsoleComponent do
  @moduledoc false

  use Phoenix.LiveComponent
  use Phoenix.HTML

  alias Archethic.TransactionChain.Transaction
  alias Archethic.TransactionChain.TransactionData
  alias Archethic.TransactionChain.TransactionData.Ledger
  alias Archethic.TransactionChain.TransactionData.TokenLedger
  alias Archethic.TransactionChain.TransactionData.TokenLedger.Transfer, as: TokenTransfer
  alias Archethic.TransactionChain.TransactionData.Ownership
  alias Archethic.TransactionChain.TransactionData.UCOLedger
  alias Archethic.TransactionChain.TransactionData.UCOLedger.Transfer, as: UCOTransfer

  defimpl Jason.Encoder, for: Archethic.TransactionChain.Transaction do
    def encode(
          %Transaction{
            version: version,
            type: type,
            data: %TransactionData{
              ledger: %Ledger{
                uco: %UCOLedger{transfers: uco_transfers},
                token: %TokenLedger{transfers: token_transfers}
              },
              code: code,
              content: content,
              recipients: recipients,
              ownerships: ownerships
            }
            #
          },
          _opts
        ) do
      %{
        "version" => version,
        "type" => Atom.to_string(type),
        "data" => %{
          "ledger" => %{
            "uco" => %{
              "transfers" =>
                Enum.map(uco_transfers, fn %UCOTransfer{to: to, amount: amount} ->
                  %{"to" => Base.encode16(to), "amount" => amount}
                end)
            },
            "token" => %{
              "transfers" =>
                Enum.map(token_transfers, fn %TokenTransfer{
                                               to: to,
                                               amount: amount,
                                               token_address: token_address,
                                               token_id: token_id
                                             } ->
                  %{
                    "to" => Base.encode16(to),
                    "amount" => amount,
                    "token" => token_address,
                    "token_id" => token_id
                  }
                end)
            }
          },
          "code" => code,
          "content" => content,
          "recipients" => Enum.map(recipients, &Base.encode16(&1)),
          "ownerships" =>
            Enum.map(ownerships, fn %Ownership{
                                      secret: secret,
                                      authorized_keys: authorized_keys
                                    } ->
              %{
                "secret" => Base.encode16(secret),
                "authorizedKeys" =>
                  Enum.map(authorized_keys, fn {public_key, encrypted_secret_key} ->
                    %{
                      "publicKey" => Base.encode16(public_key),
                      "encryptedSecretKey" => Base.encode16(encrypted_secret_key)
                    }
                  end)
              }
            end)
        }
      }
      |> Jason.encode!()
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-2/4 py-2">
      <h2 class="text-lg font-medium text-gray-400 ml-4">Console</h2>
      <div class="relative mt-2 flex-1 px-2 sm:px-2">
         <!-- Terminal -->
        <div class="absolute inset-0 px-2 sm:px-2">
          <div class="h-full border-2 border border-gray-500 bg-vs-dark text-gray-200 p-4 overflow-y-auto">
            <div class="block">
              <%= for {datetime, msg} <- @console_messages do %>
                <p>[ <%= Calendar.strftime(datetime, "%H:%M:%S:%f") %> ]<br /> <div phx-hook="CodeViewer" id={"code_viewer_#{datetime}"}><%=  raw(Jason.encode!(msg, pretty: [line_separator: "<br />", indent: "&nbsp;&nbsp;"])) %></div></p>
              <% end %>
            </div>
          </div>
        </div>
        <!-- /end Terminal -->
      </div>
    </div>
    """
  end
end
