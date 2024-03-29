defmodule ArchethicPlaygroundWeb.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_) do
    children = [
      ArchethicPlaygroundWeb.Endpoint,
      {Task.Supervisor, name: ArchethicPlaygroundWeb.TaskSupervisor},
      # some code we use might require the Archethic.TaskSupervisor
      {Task.Supervisor, name: Archethic.TaskSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
