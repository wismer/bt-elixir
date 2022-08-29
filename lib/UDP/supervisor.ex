defmodule Bittorrent.UDP.Supervisor do
  @client_id :crypto.hash(:sha, "arandomid")
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def connect_trackers([%URI{scheme: "udp", host: host, port: port} | trackers], sockets) do
    # TODO: move info_hash as a param, so it doesn't block on each iteration
    info_hash = GenServer.call(Bittorrent.Torrent, :info_hash)
    {:ok, inet6_pid} = DynamicSupervisor.start_child(
      __MODULE__,
      %{
        :id => "#{host}-inet6",
        :start => {
          Bittorrent.UDP.Socket,
          :start_link,
          [
            %{
              tracker_info: {host, port, :inet6},
              meta_info: [
               transaction_id: :rand.bytes(4),
               info_hash: info_hash,
               peer_id: @client_id,
               port: port # probably fix this
             ]
            }
          ]
        }
      }
    )
    {:ok, inet_pid} =
      DynamicSupervisor.start_child(
        __MODULE__,
        %{
          :id => host,
          :start => {
            Bittorrent.UDP.Socket,
            :start_link,
            [
              %{
                tracker_info: {host, port, :inet},
                meta_info: [
                 transaction_id: :rand.bytes(4),
                 info_hash: info_hash,
                 peer_id: @client_id,
                 port: port # probably fix this
               ]
              }
            ]
          }
        }
      )

    GenServer.cast(inet6_pid, :connect)
    GenServer.cast(inet_pid, :connect)
    connect_trackers(trackers, [inet6_pid | [inet_pid | sockets]])
  end

  def connect_trackers([tracker | trackers], sockets), do: connect_trackers(trackers, sockets)
  def connect_trackers([], sockets), do: sockets
end
