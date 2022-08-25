defmodule Bittorrent.UDP.Socket do
  use GenServer
  alias Bittorrent.UDP.Packet

  def start_link({host, port, extra}) do
    GenServer.start_link(__MODULE__, {host, port, extra}, name: String.to_atom(host))
  end

  def init({host, port, extra}) do
    IO.inspect("SOCKET INIT FOR #{host}")
    {:ok, socket} = :gen_udp.open(0, [:binary])

    result = :gen_udp.connect(socket, '#{host}', port)
    {:ok, {socket, extra}}
  end

  def handle_cast(:connect, {socket, extra}) do
    packet = Packet.build(:connect, transaction_id: extra[:transaction_id])

    case :gen_udp.send(socket, packet) do
      :ok ->
        {:noreply, {socket, extra}}
      {:error, err} -> {:stop, :error, :gen_udp.close(socket)}
    end
  end

  def handle_info({:udp, _socket, _addr, _port, data}, {socket, extra}) do
    # validate the packet first
    next_t_id = :rand.bytes(4)

    
    response_packet = data
      |> Packet.parse()
      |> Packet.validate(transaction_id: extra[:transaction_id])
      |> Packet.build(extra)

    case response_packet do
      {:ready, ips} -> {:stop, :ready, ips}
      _ -> 
        :gen_udp.send(socket, response_packet)
        {:noreply, {socket, [transaction_id: :rand.bytes(4)]}}
    end
  end
end
