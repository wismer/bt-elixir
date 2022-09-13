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

  def into_child(%URI{scheme: "udp", host: host, port: port}, info_hash) do
    for mask <- [:inet, :inet6] do
      %{
        :id => "#{host}_#{mask}",
        :start => {
          Bittorrent.UDP.Socket,
          :start_link,
          [
            %{
              tracker_info: {host, port, mask},
              meta_info: [
                transaction_id: :rand.bytes(4),
                info_hash: info_hash,
                peer_id: @client_id,
                # probably fix this
                port: port
              ]
            }
          ]
        }
      }
    end
  end

  def into_children([%URI{scheme: "udp", host: host, port: port} | trackers], children, info_hash) do
    tracker_set =
      for mask <- [:inet, :inet6] do
        %{
          :id => "#{host}_#{mask}",
          :start => {
            Bittorrent.UDP.Socket,
            :start_link,
            [
              %{
                tracker_info: {host, port, mask},
                meta_info: [
                  transaction_id: :rand.bytes(4),
                  info_hash: info_hash,
                  peer_id: @client_id,
                  # probably fix this
                  port: port
                ]
              }
            ]
          }
        }
      end

    into_children(trackers, tracker_set ++ children, info_hash)
  end

  def into_children([], children, info_hash), do: children

  def connect(children, sockets \\ []), do: connect_trackers(children, sockets)

  defp connect_trackers([child | children], sockets) do
    IO.inspect(child)

    case DynamicSupervisor.start_child(__MODULE__, child) do
      {:ok, pid} ->
        GenServer.cast(pid, :connect)
        connect_trackers(children, [pid | sockets])

      {:error, _} ->
        connect_trackers(children, sockets)
    end
  end

  defp connect_trackers([], sockets), do: sockets
end
