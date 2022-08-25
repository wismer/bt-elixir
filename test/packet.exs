defmodule PacketTest do
  use ExUnit.Case
  alias Bittorrent.UDP.Packet
  doctest Bittorrent.UDP.Packet
  @connection_id <<0x41727101980::64>>

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

    actual_result = Packet.parse(sample_binary)

    expected_result = %{
      transaction_id: t_id,
      interval: <<1914::32>>,
      leechers: <<1::32>>,
      seeders: <<1::32>>,
      ips: [{ip_2, port_2}, {ip_1, port_1}],
      size: 32,
      step: :announce
    }

    assert actual_result == expected_result
  end

  test "connect packet gets packed correctly" do
    transaction_id = :rand.bytes(4)
    actual_result = Packet.build(:connect, transaction_id: transaction_id)
    expected_result = <<@connection_id::binary, 0::32, transaction_id::binary>>

    assert actual_result == expected_result
  end

  test "connect packet response gets unpacked correctly and validates" do
    transaction_id = :rand.bytes(4)
    connect_packet = <<0::32, transaction_id::binary, @connection_id::binary>>

    actual_result =
      Packet.parse(connect_packet)
      |> Packet.validate(transaction_id: transaction_id)

    expected_result = %{
      connection_id: @connection_id,
      transaction_id: transaction_id,
      size: 16,
      step: :announce
    }

    assert actual_result == expected_result
  end

  test "a connect packet returns with an invalid message if the transaction_id is different" do
    old_transaction_id = <<22, 44, 33, 55>>
    transaction_id = <<11, 44, 33, 55>>
    connect_packet = <<0::32, transaction_id::binary, @connection_id::binary>>

    actual_result =
      Packet.parse(connect_packet)
      |> Packet.validate(transaction_id: old_transaction_id)

    expected_result = {:error, :invalid}

    assert actual_result == expected_result
  end

  test "an announce packet gets packed correctly and returns the new transaction_id" do
    transaction_id = :rand.bytes(4)
    info_hash = :rand.bytes(20)
    peer_id = :rand.bytes(20)
    

    expected_packet = <<
      @connection_id::binary,
      1::32,
      transaction_id::binary,
      info_hash::binary,
      peer_id::binary,
      0::64,
      0::64,
      0::64,
      0::32,
      0::32,
      0::32,
      -1::32,
      1337::16
    >>

    actual_packet =
      Packet.build(
        %{step: :announce},
        transaction_id: transaction_id,
        info_hash: info_hash,
        peer_id: peer_id,
        port: 1337
      )

    assert actual_packet == expected_packet
  end
end
