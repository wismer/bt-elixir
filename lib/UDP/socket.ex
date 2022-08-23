defmodule Bittorrent.UDP.Socket do
  use GenServer
  alias Bittorrent.UDP.Packet
  @client_id :crypto.hash(:sha, "replacemewithsomethingelse")

  def start_link({host, port, extra}) do
    GenServer.start_link(__MODULE__, {host, port, extra}, name: String.to_atom(host))
  end

  def init({host, port, extra}) do
    IO.inspect("SOCKET INIT FOR #{host}")
    {:ok, socket} = :gen_udp.open(0, [:binary])

    result = :gen_udp.connect(socket, '#{host}', port)

    IO.inspect({socket, extra, result})
    {:ok, {socket, extra}}
  end

  def handle_cast(:connect, {socket, extra}) do
    packet = Packet.pack_connect(Keyword.get(extra, :transaction_id))
    IO.inspect({:packet, packet})
    # packet = Packet.pack([
    #   {connection_id, 64},
    #   {1, 32},
    #   {transaction_id, 32},
    #   {@sample_hash, 160},
    #   {@client_id, 160},
    #   {0, 64},
    #   {0, 64},
    #   {0, 64},
    #   {2, 32},
    #   {0, 32},
    #   {0, 32},
    #   {-1, 32},
    #   {port, 16}
    # ])
    case :gen_udp.send(socket, packet) do
      :ok ->
        {:noreply, {socket, extra}}
      {:error, err} -> IO.inspect(err) 
    end
  end

  def handle_info(arg1, arg2) do
    IO.inspect({arg1, arg2})
  end

  def handle_info({:udp, _socket, _addr, _port, data}, {socket, extra}) do
    # validate the packet first
    
    # case data do
    #   <<0::32, packet::binary>> -> handle_connect(packet, socket, port, addr)
    #   <<1::32, packet::binary>> -> handle_announce(packet, socket, port, addr)
    #   <<2::32, packet::binary>> -> handle_scrape(packet, socket, port, addr)
    #   <<3::32, packet::binary>> -> handle_error(packet, socket, port, addr)
    #   _ -> {:stop, :unrecognized_packet}
    # end
    
    {:noreply, {socket, [transaction_id: :rand.bytes(4)]}}
  end
end
