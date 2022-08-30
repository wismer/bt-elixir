defmodule Bittorrent.UDP.Packet do
  @connection_id <<0x41727101980::64>>

  def parse(<<0::32, packet::binary>> = buffer), do:
    unpack([{:transaction_id, 4}, {:connection_id, 8}], packet, %{
      step: :connect,
      size: byte_size(buffer)
    })

  def parse(<<1::32, packet::binary>> = buffer), do: unpack(
      [
        {:transaction_id, 4},
        {:interval, 4},
        {:leechers, 4},
        {:seeders, 4},
        {:ips, 4},
        {:ports, 2}
      ],
      packet,
      %{
        step: :announce,
        size: byte_size(buffer)
      }
    )

  def parse(<<2::32, packet::binary>>), do: {:error, :not_implemented}
  def parse(<<3::32, packet::binary>>), do: parse_error(packet)
  def parse(packet), do: {:error, :invalid}

  defp parse_error(<<_t_id::size(4), rest::binary>>) do
    IO.inspect("#{rest}")
    {:error, :invalid}
  end


  # UNPACKING

  defp unpack([], <<>>, parts), do: parts

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

  # PACKING

  def build(:connect, transaction_id: t_id), do: pack_connect(t_id)
  def build(%{step: :announce, connection_id: conn_id} = rest, fields), 
    do: pack_announce(fields, conn_id)
  
  def build(%{step: :uh_oh, ips: ips}, _fields), do: {:ready, ips}

  defp pack_connect(t_id), do: pack([{@connection_id, 64}, {0, 32}, {t_id, 32}], <<>>)
  defp pack_announce(fields, conn_id) do
    pack(
      [
        {conn_id, 64}, # conn_id
        {1, 32}, # action
        {Keyword.get(fields, :transaction_id), 32},
        {Keyword.get(fields, :info_hash), 160},
        {Keyword.get(fields, :peer_id), 160},
        # downloaded
        {0, 64},
        # left
        {0, 64},
        # uploaded
        {0, 64},
        # will need to make this dynamic?
        {1, 32},
        # event 
        {0, 32},
        # key
        {0, 32},
        # num want
        {-1, 32},
        {Keyword.get(fields, :port), 16}
      ],
      <<>>
    )
  end

  defp pack([{n, bits} | rest], buffer) when is_binary(n), do: pack(rest, buffer <> n)
  defp pack([{n, bits} | rest], buffer), do: pack(rest, buffer <> <<n::size(bits)>>)
  defp pack([], buffer), do: buffer

  def validate(%{transaction_id: current_t_id, size: size} = parts,
        transaction_id: t_id
      ) do
      key = case parts[:step] do
        :connect -> :announce
        :announce -> :uh_oh # make up something professional, for crying out loud.
      end
      %{parts | step: key}
  end

  def validate(parts, fields), do: {:error, :invalid}
end
