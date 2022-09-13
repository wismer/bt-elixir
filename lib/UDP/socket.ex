defmodule Bittorrent.UDP.Socket do
  use GenServer
  alias Bittorrent.UDP.Packet

  def start_link(%{tracker_info: {host, _port, protocol}} = opts) do
    GenServer.start_link(__MODULE__, opts, name: String.to_atom("#{host}_#{protocol}"))
  end

  def init(%{tracker_info: {host, port, protocol}} = opts) do
    {:ok, socket} = :gen_udp.open(0, [:binary, protocol, active: true])

    addr =
      case :inet.getaddr('#{host}', protocol) do
        {:ok, ip} -> ip
        {:error, _} -> '#{host}'
      end

    case :gen_udp.connect(socket, addr, port) do
      :ok -> {:ok, {socket, Map.get(opts, :meta_info)}}
      {:error, reason} -> {:stop, reason}
    end
  end

  def handle_cast(:connect, {socket, extra} = rest) do
    packet = Packet.build(:connect, transaction_id: extra[:transaction_id])

    case :gen_udp.send(socket, packet) do
      :ok ->
        {:noreply, {socket, extra}}

      {:error, err} ->
        # IO.inspect(err)
        {:stop, :error, :gen_udp.close(socket)}
    end
  end

  def handle_info({:udp, _socket, _addr, _port, data}, {socket, extra}) do
    # validate the packet first
    next_t_id = :rand.bytes(4)

    response_packet =
      data
      |> Packet.parse()
      |> Packet.validate(transaction_id: extra[:transaction_id])
      |> Packet.build(extra)

    case response_packet do
      {:ready, ips} ->
        GenServer.cast(Bittorrent.Torrent, {:peers, ips})
        {:stop, :peers, ips}

      _ ->
        :gen_udp.send(socket, response_packet)
        {:noreply, {socket, [transaction_id: :rand.bytes(4)]}}
    end
  end
end
