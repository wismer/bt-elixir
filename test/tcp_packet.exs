defmodule PacketTest do
  use ExUnit.Case
  alias Bittorrent.TCP.Packet
  doctest Bittorrent.TCP.Packet

  test "parses the bitfield correctly" do
    # 21 pieces should be accounted for, starting from the most significant bit
    # leftover bits are discarded.
    # raw_bitfield = Integer.parse("011111001111110010111000", 2) 
    raw_bitfield = <<124, 252, 184>>
    expected_bitfield = [0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 1, 1, 1]
    IO.inspect(<<29::size(32), 5>> <> raw_bitfield)
    result = Packet.unpack(<<22::size(32), 5::size(8)>> <> raw_bitfield)
    assert expected_bitfield == result
  end
end
