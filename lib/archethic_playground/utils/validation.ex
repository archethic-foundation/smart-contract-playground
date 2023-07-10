defmodule ArchethicPlayground.Utils.Validation do
  import Ecto.Changeset

  # todo: field should be a list
  def validate_base_16_address(changeset, field) do
    with value <- fetch_field!(changeset, field),
         false <- is_nil(value),
         changeset <- update_change(changeset, field, &String.upcase/1),
         true <- is_invalid_address(value) do
      add_error(changeset, field, "is not a valid address")
    else
      _ -> changeset
    end
  end

  defp is_invalid_address(authorized_key_address) do
    authorized_key_address = String.upcase(authorized_key_address)

    case Base.decode16(authorized_key_address) do
      :error -> true
      {:ok, decoded} -> not Archethic.Crypto.valid_address?(decoded)
    end
  end
end
