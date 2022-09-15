defmodule Bittorrent.Downloader do
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    {:ok, state, {:continue, nil}}
  end

  def handle_info({:ips, ips}, state) do
    {:noreply, Map.put(state, :peers, Enum.dedup(state[:peers] ++ ips))}
  end

  def handle_info(msg, state) do
    {:noreply, state}
  end

  def handle_call(msg, state) do
    IO.inspect(msg)
    {:noreply, state}
  end

  def handle_continue(_, %{torrent: torrent, peer_id: peer_id, info_hash: info_hash} = state) do
    if torrent["announce-list"] do
      for tracker <- torrent["announce-list"] do
        start_tracker(tracker, peer_id: peer_id, info_hash: info_hash)
      end
    else
      start_tracker(torrent["announce"], peer_id: peer_id, info_hash: info_hash)
    end

    {:noreply, state}
  end

  defp start_tracker(%URI{scheme: "udp"} = tracker, peer_id: peer_id, info_hash: info_hash) do
    # start UDP tracker
  end

  defp start_tracker(%URI{scheme: "https"} = tracker, peer_id: peer_id, info_hash: info_hash) do
    url_params =
      URI.encode_query(%{
        info_hash: info_hash,
        peer_id: peer_id,
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

    ips = Bittorrent.UDP.Packet.unpack_ips(res.body, [])

    send(self(), {:ips, ips})
  end

end
