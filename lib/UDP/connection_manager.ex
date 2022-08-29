defmodule Bittorrent.UDP.ConnectionManager do
  alias Bittorrent.UDP.Supervisor, as: SocketSupervisor
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    # tracker / info hash call can get merged, maybe
    trackers =
      GenServer.call(Bittorrent.Torrent, :trackers)
      |> SocketSupervisor.connect_trackers([])

    {:ok, trackers}
  end
end
