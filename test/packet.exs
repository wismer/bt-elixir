defmodule PacketTest do
  use ExUnit.Case
  doctest Bittorrent.UDP.Packet

  test "unpacks an announce packet correctly" do
    t_id = :rand.bytes(4)
    ip_1 = :rand.bytes(4)
    port_1 = :rand.bytes(2)
    ip_2 = :rand.bytes(4)
    port_2 = :rand.bytes(2)
    sample_binary = <<
      1::32,
      t_id::binary, 
      1914::32, 
      1::32, 
      1::32, 
      ip_1::binary, 
      port_1::binary, 
      ip_2::binary,
      port_2::binary
    >>
    IO.inspect(sample_binary)
    actual_result = Bittorrent.UDP.Packet.unpack_announce(sample_binary)
    expected_result = %{
      transaction_id: t_id,
      interval: <<1914::32>>,
      leechers: <<1::32>>,
      seeders: <<1::32>>,
      ips: [{ip_2, port_2}, {ip_1, port_1}]
    }
    assert actual_result == expected_result
  end
end
