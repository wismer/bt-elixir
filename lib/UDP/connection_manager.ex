defmodule Bittorrent.UDP.ConnectionManager do
  alias Bittorrent.UDP.Supervisor, as: SocketSupervisor
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    # tracker / info hash call can get merged, maybe
    {trackers, info_hash} = GenServer.call(Bittorrent.Torrent, :trackers)

    for tracker <- trackers, tracker.scheme == "https" do
      Task.start(fn ->
        url_params =
          URI.encode_query(%{
            info_hash: info_hash,
            peer_id: :crypto.hash(:sha, "arandomid"),
            port: 6881,
            uploaded: 0,
            downloaded: 0,
            left: 0,
            compact: 1,
            event: "started"
          })

        {:ok, res} =
          Finch.build(:get, "https://#{tracker.host}#{tracker.path}?#{url_params}")
          |> Finch.request(Bittorrent.HTTP.Socket)

        Bittorrent.UDP.Packet.unpack_ips(res.body, []) |> IO.inspect()
      end)
    end

    # sockets = trackers
    #   |> Enum.map(fn tracker -> SocketSupervisor.into_child(tracker, info_hash) end)
    #   |> List.flatten()
    #   |> SocketSupervisor.connect()
    {:ok, nil}
  end
end
