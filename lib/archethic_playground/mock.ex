defmodule ArchethicPlayground.Mock do
  @moduledoc false

  @type t :: %__MODULE__{
          function: String.t(),
          inputs: list(any()),
          output: any()
        }

  @derive Jason.Encoder
  defstruct [:function, :inputs, :output]

  def cast(%{function: "Time.now/0", inputs: [], output: datetime_iso}) when is_binary(datetime_iso) do
    {:ok, datetime, _} = DateTime.from_iso8601(datetime_iso)
    %__MODULE__{function: "Time.now/0", inputs: [], output: datetime}
  end

  def cast(%{function: function_name, inputs: inputs, output: output}) do
    %__MODULE__{function: function_name, inputs: inputs, output: output}
  end
end
