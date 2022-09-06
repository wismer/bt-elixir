defmodule Bittorrent.TCP.Piece do
  use GenServer

  def start_link(piece) do
    GenServer.start_link(__MODULE__, piece, name: __MODULE__)
  end

  def init(piece) do
    {:ok, piece}
  end

  def handle_cast({:block, data, index}, piece) do
    
  end
end

