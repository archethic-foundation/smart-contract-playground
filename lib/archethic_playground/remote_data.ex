defmodule ArchethicPlayground.RemoteData do
  @moduledoc """
  naive implementation of https://package.elm-lang.org/packages/krisajenkins/remotedata/latest/RemoteData
  """

  @type t() :: %__MODULE__{
          status: :not_asked | :loading | {:failure, any()} | {:success, any()}
        }

  defstruct status: :not_asked

  def success(result), do: %__MODULE__{status: {:success, result}}
  def failure(reason), do: %__MODULE__{status: {:failure, reason}}
  def loading(), do: %__MODULE__{status: :loading}

  def loading?(%__MODULE__{status: :loading}), do: true
  def loading?(%__MODULE__{}), do: false

  def success?(%__MODULE__{status: {:success, _}}), do: true
  def success?(%__MODULE__{}), do: false

  def failure?(%__MODULE__{status: {:failure, _}}), do: true
  def failure?(%__MODULE__{}), do: false

  # you're not really supposed to get the result of anything else but success
  # so let it crash (we use this because there's no case in HEEX)
  def result(%__MODULE__{status: {:success, result}}), do: result

  # you're not really supposed to get the error of anything else but failure
  # so let it crash (we use this because there's no case in HEEX)
  def error(%__MODULE__{status: {:failure, error}}), do: error
end
