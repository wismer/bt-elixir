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

  def handle_call(:trackers, _, state) do
    # TO DO: The encoding isn't quite right - the sha1 hash isn't matching! TIME WASTED!
    # I don't think the encoding was working because it wasn't encoding the `value` of the dictionary,
    # - before it was encoding `%{"pieces" => state["info"]}` which is not correct. Have not 
    # been able to verify this yet, however.
    tracker_list = Bencode.encode(state["info"]) 
    info_hash = :crypto.hash(:sha, tracker_list)

    if state["announce-list"] do
      trackers = state["announce-list"]
      {:reply, {trackers, info_hash}, state}
    else
      {:reply, [state["announce"]], state}
    end
  end

  def handle_cast({:peers, peers}, state) do
    IO.inspect(peers)
    {:noreply, state}
  end
end
