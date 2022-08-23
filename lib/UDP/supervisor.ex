defmodule Bittorrent.UDP.Supervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def connect_trackers([%URI{scheme: "udp", host: host, port: port} | trackers], sockets) do
    info_hash = GenServer.call(Bittorrent.Torrent, :info_hash)

    {:ok, pid} =
      DynamicSupervisor.start_child(
        __MODULE__,
        %{
          :id => host,
          :start => {
            Bittorrent.UDP.Socket,
            :start_link,
            [{host, port, [transaction_id: :rand.bytes(4), info_hash: info_hash]}]
          }
        }
      )

    GenServer.cast(pid, :connect)

    connect_trackers(trackers, [pid | sockets])
  end

  def connect_trackers([tracker | trackers], sockets), do: connect_trackers(trackers, sockets)
  def connect_trackers([], sockets), do: sockets
end
