defmodule Bittorrent.Tracker do
  defstruct [:host, :port, :peer_id, :info_hash]
  use GenServer

  def start_link(%{tracker: tracker} = state) do
    GenServer.start_link(__MODULE__, state, name: via(tracker.host))
  end

  def init(%{tracker: %URI{ host: host, port: port, scheme: "udp" }} = state) do
    {:ok, state}
  end


  def init(%{tracker: %URI{ host: host, path: path, scheme: "https" }, info_hash: info_hash} = state) do
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

    {:ok, res} = Finch.build(:get, "https://#{host}#{path}?#{url_params}")
      |> Finch.request(Bittorrent.HTTP.Socket)

    res = GenServer.call(Bittorrent.Downloader, :hello)
    IO.inspect(res)
    {:stop, :req_made}
  end

  def handle_info(:req, state) do
    IO.inspect("slkdfjsldkfj")
    {:noreply, state}
  end

  def handle_cast(req, state) do
    {:noreply, state}
  end

  def handle_info(msg, state) do
    IO.inspect("HANDLE INFO")
    {:noreply, state}
  end

  def handle_call(req, from, state) do
    IO.inspect("HANDLE CALL")
    {:noreply, state}
  end


  defp via(host) do
    {:via, Registry, {Bittorrent.TrackerRegistry, host}}
  end
end
