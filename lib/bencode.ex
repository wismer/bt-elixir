defmodule Bittorrent.Bencode do
  use GenServer

  def start_link(_) do
    IO.inspect("start link for Bencode")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_init_state) do
    IO.inspect("bencode init")
    {:ok, parse_torrent()}
  end

  def parse_torrent(torrent_file \\ "../../../Downloads/big-buck-bunny.torrent") do
    File.read!(torrent_file)
    |> IO.iodata_to_binary()
    |> decode()
    |> into_uri()
  end

  def decode(<<"i", rest::binary>>), do: decode_i(rest)
  def decode(<<"l", rest::binary>>), do: decode_l(rest)
  def decode(<<"d", rest::binary>>), do: decode_d(rest)
  def decode(other), do: decode_b(other)

  defp decode_b(data), do: decode_b_read_len(data)
  defp decode_b_read_len(data, acc \\ "")

  defp decode_b_read_len(<<":", rest::binary>>, acc) do
    {len, _} = Integer.parse(acc)
    decode_b_read_data(rest, len, "")
  end

  defp decode_b_read_len(<<d::binary-size(1), rest::binary>>, acc) do
    decode_b_read_len(rest, acc <> d)
  end

  defp decode_b_read_data(rest, 0, acc) do
    {acc, rest}
  end

  defp decode_b_read_data(<<d::binary-size(1), rest::binary>>, c, acc) do
    decode_b_read_data(rest, c - 1, acc <> d)
  end

  defp decode_i(data, acc \\ "")

  defp decode_i(<<"e", rest::binary>>, acc) do
    {n, _} = Integer.parse(acc)
    {n, rest}
  end

  defp decode_i(<<c::binary-size(1), rest::binary>>, acc), do: decode_i(rest, acc <> c)

  defp decode_l(data, acc \\ [])

  defp decode_l(<<"e", rest::binary>>, acc) do
    {acc, rest}
  end

  defp decode_l(data, acc) do
    {item, rest} = decode(data)
    decode_l(rest, acc ++ [item])
  end

  defp decode_d(data, acc \\ %{})
  defp decode_d(<<"e", rest::binary>>, acc), do: {acc, rest}

  defp decode_d(data, acc) do
    {key, rest} = decode_b(data)
    {value, rest_} = decode(rest)
    decode_d(rest_, acc |> Map.merge(%{key => value}))
  end

  def encode(data) when is_integer(data), do: [?i, Integer.to_string(data), ?e]

  def encode(data) when is_binary(data) do
    [data |> byte_size() |> Integer.to_string(), ?:, data]
  end

  def encode(data) when is_list(data) do
    [?l, Enum.map(data, &encode/1), ?e]
  end

  def encode(data) when is_map(data) do
    [?d, Enum.map(data, fn {k, v} -> [encode(k), encode(v)] end), ?e]
  end

  def into_uri({data, r}) do
    data =
      update_in(data["announce-list"], fn urls ->
        cmon =
          Stream.map(urls, fn [url | _] ->
            case URI.new(url) do
              {:ok, uri} -> uri
              {:error, _} -> nil
            end
          end)

        Enum.to_list(cmon)
      end)

    data
  end
end
