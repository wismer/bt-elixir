defmodule Bittorrent do
  use Application
  alias Bittorrent.Bencode

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
    {info_hash, torrent_data} = Bencode.parse_torrent()

    children = [
      # Maybe `Torrent` doesn't need to be a process?
      {Finch, name: Bittorrent.HTTP.Socket},
      {Registry, keys: :unique, name: Bittorrent.PeerRegistry},
      {Registry, keys: :unique, name: Bittorrent.TrackerRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: Bittorrent.PeerSupervisor},
      {DynamicSupervisor, strategy: :one_for_one, name: Bittorrent.TrackerSupervisor},
      {Bittorrent.Downloader,
       %{
         torrent: torrent_data,
         peers: [],
         peer_id: :crypto.hash(:sha, "arandomid"),
         info_hash: info_hash
       }}
      # Also change this...
      # Bittorrent.Torrent,
      # Bittorrent.TCP.Supervisor,
      # Bittorrent.UDP.Supervisor,
      # Bittorrent.UDP.ConnectionManager
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
