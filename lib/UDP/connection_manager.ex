defmodule Bittorrent.UDP.ConnectionManager do
  alias Bittorrent.UDP.Supervisor, as: SocketSupervisor
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    # tracker / info hash call can get merged, maybe
    {trackers, info_hash} = GenServer.call(Bittorrent.Torrent, :trackers)
    IO.inspect(info_hash)
    sockets = trackers
      |> Enum.map(fn tracker -> SocketSupervisor.into_child(tracker, info_hash) end)
      |> List.flatten()
      |> SocketSupervisor.connect()
    {:ok, sockets}
  end
end
