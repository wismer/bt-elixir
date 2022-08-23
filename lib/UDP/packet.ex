defmodule Bittorrent.UDP.Packet do
  @connection_id <<0x41727101980::64>>

  def pack_connect(t_id), do: pack([{@connection_id, 64}, {0, 32}, {t_id, 32}], <<>>)

  def pack_announce(fields) do
    pack(
      [
        {@connnection_id, 64},
        {1, 32},
        {Keyword.get(fields, :transaction_id), 32},
        {Keyword.get(fields, :info_hash), 160},
        {Keyword.get(fields, :peer_id), 160},
        # downloaded
        {0, 64},
        # left
        {0, 64},
        # uploaded
        {0, 64},
        {Keyword.get(fields, :event), 32},
        # event 
        {0, 32},
        # key
        {0, 32},
        {Keyword.get(fields, :port), 16}
      ],
      <<>>
    )
  end

  def unpack_connect(<<0::32, rest::binary>>),
    do: unpack([{:transaction_id, 32}, {:connection_id, 64}], rest, [])

  def unpack_announce(<<1::32, rest::binary>>) do
    unpack(
      [
        {:transaction_id, 4},
        {:interval, 4},
        {:leechers, 4},
        {:seeders, 4},
        {:ips, 4},
        {:ports, 2}
      ],
      rest,
      %{}
    )
  end
  
  defp unpack([], <<>>, kwords), do: kwords
  defp unpack([{:ips, _ip_s} | [{:ports, _p_s} | rest]], buffer, parts) do
    ips = unpack_ips(buffer, [])
    Map.put(parts, :ips, ips)
  end

  defp unpack([{k, v} | fields], buffer, parts) do
    <<packet_part::binary-size(v), rest::binary>> = buffer
    unpack(fields, rest, Map.put(parts, k, packet_part))
  end

  def unpack_ips(<<ip::binary-size(4), port::binary-size(2), rest::binary>>, ips),
    do: unpack_ips(rest, [{ip, port} | ips])
  def unpack_ips(<<>>, ips), do: ips


  defp pack([{n, bits} | rest], buffer) when is_binary(n), do: pack(rest, buffer <> n)
  defp pack([{n, bits} | rest], buffer), do: pack(rest, buffer <> <<n::size(bits)>>)
  defp pack([], buffer), do: buffer
end


# sample = Bittorrent.UDP.Packet.unpack_ips(<<5672::32, 1337::16, 3245::32, 8080::16>>, [])
sample = Bittorrent.UDP.Packet.unpack_announce(<<1::32, 132, 136, 245, 118, 0, 0, 6, 111, 0, 0, 0, 0, 0, 0, 0, 2, 47, 16, 147, 26, 5, 57, 47, 16, 44, 220, 5, 57, 2352::32, 1337::16>>)
IO.inspect(sample)