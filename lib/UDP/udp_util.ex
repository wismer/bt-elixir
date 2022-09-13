defmodule Bittorrent.UDP.UDPUtil do
  def get_eligible_addrs(host, addrs, [type | types]) do
    case :inet.getaddr('#{host}', type) do
      {:ok, addr} -> get_eligible_addrs(host, [addr | addrs], types)
      {:error, _} -> get_eligible_addrs(host, addrs, types)
    end
  end

  def get_eligible_addrs(host, addrs, []), do: addrs
end
