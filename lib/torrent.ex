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
    tracker_list = Bencode.encode(%{"pieces" => state["info"]})
    if state["announce-list"] do
      trackers = for tracker <- state["announce-list"], tracker.scheme == "udp" do
        tracker
      end
      {:reply, {trackers, <<201, 223, 231, 8, 104, 161, 66, 9, 79, 92, 249, 112, 202,
      17, 45, 224, 183, 59, 200, 80>>}, state}
    else
      {:reply, [state["announce"]], state}
    end
  end

  def handle_cast({:peers, peers}, state) do
    IO.inspect(peers)
    {:noreply, state}
  end
end
