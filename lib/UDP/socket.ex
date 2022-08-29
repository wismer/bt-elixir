defmodule Bittorrent.UDP.Socket do
  use GenServer
  alias Bittorrent.UDP.Packet

  def start_link(%{tracker_info: { host, _port, protocol }} = opts) do
    GenServer.start_link(__MODULE__, opts, name: String.to_atom("#{host}_#{protocol}"))
  end

  def init(%{ tracker_info: {host, port, protocol}} = opts) do
    IO.inspect("SOCKET INIT FOR #{host}-#{protocol}")
    {:ok, socket} = :gen_udp.open(0, [:binary, protocol])
    addr_info(host, protocol)
    result = :gen_udp.connect(socket, '#{host}', port)
    {:ok, {socket, Map.get(opts, :meta_info)}}
  end

  def addr_info(host, protocol) do
    IO.inspect({:result, :inet.getaddr('#{host}', protocol), host, protocol})
  end

  def handle_cast(:connect, {socket, extra} = rest) do
    IO.inspect(rest)  
    packet = Packet.build(:connect, transaction_id: extra[:transaction_id])

    case :gen_udp.send(socket, packet) do
      :ok ->
        {:noreply, {socket, extra}}
      {:error, err} -> 
        # IO.inspect(err)
        {:stop, :error, :gen_udp.close(socket)}
    end
  end

  def handle_info(oops, rest) do
    IO.inspect(rest)
  end

  def handle_info({:udp, _socket, _addr, _port, data}, {socket, extra}) do
    # validate the packet first
    next_t_id = :rand.bytes(4)

    
    response_packet = data
      |> Packet.parse()
      |> Packet.validate(transaction_id: extra[:transaction_id])
      |> Packet.build(extra)

    case response_packet do
      {:ready, ips} -> 
        IO.inspect(ips)
        {:stop, :ready, ips}
      _ -> 
        :gen_udp.send(socket, response_packet)
        {:noreply, {socket, [transaction_id: :rand.bytes(4)]}}
    end
  end
end
