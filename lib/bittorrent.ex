defmodule Bittorrent do
  use Application

  @moduledoc """
  Documentation for `Bittorrent`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Bittorrent.hello()
      :world

  """
  def hello do
    :world
  end

  @impl true
  def start(_, _) do
    IO.inspect("APP START")

    children = [
      # Maybe `Torrent` doesn't need to be a process?

      Bittorrent.Torrent,
      Bittorrent.TCP.Supervisor,
      Bittorrent.UDP.Supervisor,
      Bittorrent.UDP.ConnectionManager
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
