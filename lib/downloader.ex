defmodule Bittorrent.Downloader do
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    {:ok, state, {:continue, nil}}
  end

  def handle_continue(_, %{torrent: torrent, peer_id: peer_id, info_hash: info_hash} = state) do
    if torrent["announce-list"] do
      for tracker <- torrent["announce-list"] do
        DynamicSupervisor.start_child(
          Bittorrent.TrackerSupervisor,
          {Bittorrent.Tracker, %{tracker: tracker, info_hash: info_hash, peer_id: peer_id}}
        )
      end
    else
      DynamicSupervisor.start_child(
        Bittorrent.TrackerSupervisor,
        {Bittorrent.Tracker, %{tracker: torrent["announce"], info_hash: info_hash, peer_id: peer_id}}
      )
    end

    {:noreply, state}
  end
end
