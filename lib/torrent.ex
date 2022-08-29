defmodule Bittorrent.Torrent do
  use GenServer
  alias Bittorrent.Bencode

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(_) do
    torrent_data = Bencode.parse_torrent()
    IO.inspect(torrent_data)
    {:ok, torrent_data}
  end

  def handle_call(:info_hash, _, state) do
    tracker_list = Bencode.encode(%{"pieces" => state["info"]})
    sha_hash = :crypto.hash(:sha, tracker_list)
    {:reply, sha_hash, state}
  end

  def handle_call(:trackers, _, state) do
    if state["announce-list"] do
      {:reply,
        for tracker <- state["announce-list"], tracker.scheme == "udp" do
          tracker
        end, state}
    else
      {:reply, [state["announce"]], state}
    end
  end
end
