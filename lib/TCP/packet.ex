defmodule Bittorrent.TCP.Packet do
  @pstr "BitTorrent Protocol"
  @reserved <<0, 0, 0, 0, 0, 0, 0, 0>>

  # def handshake(hash, peer_id) do
  #   byte_size(@pstr)
  #     |> Integer.to_string(16) <> @pstr <> @reserved <> hash <> peer_id
  # end

  # def unpack(<<len::binary-size(4), id::binary-size(1), rest::binary>>) do
  #   case :binary.decode_unsigned(id) do
  #     0 when byte_size(rest) == 0 -> {:keep_alive, nil}
  #     0 -> {:choke, nil}
  #     1 -> {:unchoke, nil}
  #     2 -> {:interested, nil}
  #     3 -> {:not_interested, nil}
  #     _ -> nil
  #   end
  # end

  def unpack(<<_len::integer-size(32)>>), do: {:keep_alive}
  def unpack(<<_len::integer-size(32), 0>>), do: {:choke}
  def unpack(<<_len::integer-size(32), 1>>), do: {:unchoke}
  def unpack(<<_len::integer-size(32), 2>>), do: {:interested}
  def unpack(<<_len::integer-size(32), 3>>), do: {:not_interested}

  def unpack(<<len::integer-size(32), 4, piece_index::binary>>),
    do: {:have, piece_index}

  def unpack(<<len::integer-size(32), 5, bitfield::binary>>) do
    IO.inspect(len)
    unpack_bitfield(len - 8, :binary.decode_unsigned(bitfield), [])
  end

  defp unpack_bitfield(0, bitfield, pieces), do: pieces

  defp unpack_bitfield(len, bitfield, pieces),
    do:
      unpack_bitfield(len - 1, bitfield, [
        Bitwise.bsr(bitfield, len - 1) |> Bitwise.band(1) | pieces
      ])
end

# Handshake
# The handshake is a required message and must be the first message transmitted by the client. It is (49+len(pstr)) bytes long.

# handshake: <pstrlen><pstr><reserved><info_hash><peer_id>

# pstrlen: string length of <pstr>, as a single raw byte
# pstr: string identifier of the protocol
# reserved: eight (8) reserved bytes. All current implementations use all zeroes. Each bit in these bytes can be used to change the behavior of the protocol. An email from Bram suggests that trailing bits should be used first, so that leading bits may be used to change the meaning of trailing bits.
# info_hash: 20-byte SHA1 hash of the info key in the metainfo file. This is the same info_hash that is transmitted in tracker requests.
# peer_id: 20-byte string used as a unique ID for the client. This is usually the same peer_id that is transmitted in tracker requests (but not always e.g. an anonymity option in Azureus).
# In version 1.0 of the BitTorrent protocol, pstrlen = 19, and pstr = "BitTorrent protocol".

# The initiator of a connection is expected to transmit their handshake immediately. The recipient may wait for the initiator's handshake, if it is capable of serving multiple torrents simultaneously (torrents are uniquely identified by their infohash). However, the recipient must respond as soon as it sees the info_hash part of the handshake (the peer id will presumably be sent after the recipient sends its own handshake). The tracker's NAT-checking feature does not send the peer_id field of the handshake.

# If a client receives a handshake with an info_hash that it is not currently serving, then the client must drop the connection.

# If the initiator of the connection receives a handshake in which the peer_id does not match the expected peerid, then the initiator is expected to drop the connection. Note that the initiator presumably received the peer information from the tracker, which includes the peer_id that was registered by the peer. The peer_id from the tracker and in the handshake are expected to match.

# peer_id
# The peer_id is exactly 20 bytes (characters) long.
# Messages
# All of the remaining messages in the protocol take the form of <length prefix><message ID><payload>. The length prefix is a four byte big-endian value. The message ID is a single decimal byte. The payload is message dependent.

# keep-alive: <len=0000>
# The keep-alive message is a message with zero bytes, specified with the length prefix set to zero. There is no message ID and no payload. Peers may close a connection if they receive no messages (keep-alive or any other message) for a certain period of time, so a keep-alive message must be sent to maintain the connection alive if no command have been sent for a given amount of time. This amount of time is generally two minutes.

# choke: <len=0001><id=0>
# The choke message is fixed-length and has no payload.

# unchoke: <len=0001><id=1>
# The unchoke message is fixed-length and has no payload.

# interested: <len=0001><id=2>
# The interested message is fixed-length and has no payload.

# not interested: <len=0001><id=3>
# The not interested message is fixed-length and has no payload.

# have: <len=0005><id=4><piece index>
# The have message is fixed length. The payload is the zero-based index of a piece that has just been successfully downloaded and verified via the hash.

# Implementer's Note: That is the strict definition, in reality some games may be played. In particular because peers are extremely unlikely to download pieces that they already have, a peer may choose not to advertise having a piece to a peer that already has that piece. At a minimum "HAVE suppression" will result in a 50% reduction in the number of HAVE messages, this translates to around a 25-35% reduction in protocol overhead. At the same time, it may be worthwhile to send a HAVE message to a peer that has that piece already since it will be useful in determining which piece is rare.

# A malicious peer might also choose to advertise having pieces that it knows the peer will never download. Due to this attempting to model peers using this information is a bad idea.

# bitfield: <len=0001+X><id=5><bitfield>
# The bitfield message may only be sent immediately after the handshaking sequence is completed, and before any other messages are sent. It is optional, and need not be sent if a client has no pieces.

# The bitfield message is variable length, where X is the length of the bitfield. The payload is a bitfield representing the pieces that have been successfully downloaded. The high bit in the first byte corresponds to piece index 0. Bits that are cleared indicated a missing piece, and set bits indicate a valid and available piece. Spare bits at the end are set to zero.

# Some clients (Deluge for example) send bitfield with missing pieces even if it has all data. Then it sends rest of pieces as have messages. They are saying this helps against ISP filtering of BitTorrent protocol. It is called lazy bitfield.

# A bitfield of the wrong length is considered an error. Clients should drop the connection if they receive bitfields that are not of the correct size, or if the bitfield has any of the spare bits set.

# request: <len=0013><id=6><index><begin><length>
# The request message is fixed length, and is used to request a block. The payload contains the following information:

# index: integer specifying the zero-based piece index
# begin: integer specifying the zero-based byte offset within the piece
# length: integer specifying the requested length.
# This section is under dispute! Please use the discussion page to resolve this!

# View #1 According to the official specification, "All current implementations use 2^15 (32KB), and close connections which request an amount greater than 2^17 (128KB)." As early as version 3 or 2004, this behavior was changed to use 2^14 (16KB) blocks. As of version 4.0 or mid-2005, the mainline disconnected on requests larger than 2^14 (16KB); and some clients have followed suit. Note that block requests are smaller than pieces (>=2^18 bytes), so multiple requests will be needed to download a whole piece.

# Strictly, the specification allows 2^15 (32KB) requests. The reality is near all clients will now use 2^14 (16KB) requests. Due to clients that enforce that size, it is recommended that implementations make requests of that size. Due to smaller requests resulting in higher overhead due to tracking a greater number of requests, implementers are advised against going below 2^14 (16KB).

# The choice of request block size limit enforcement is not nearly so clear cut. With mainline version 4 enforcing 16KB requests, most clients will use that size. At the same time 2^14 (16KB) is the semi-official (only semi because the official protocol document has not been updated) limit now, so enforcing that isn't wrong. At the same time, allowing larger requests enlarges the set of possible peers, and except on very low bandwidth connections (<256kbps) multiple blocks will be downloaded in one choke-timeperiod, thus merely enforcing the old limit causes minimal performance degradation. Due to this factor, it is recommended that only the older 2^17 (128KB) maximum size limit be enforced.

# View #2 This section has contained falsehoods for a large portion of the time this page has existed. This is the third time I (uau) am correcting this same section for incorrect information being added, so I won't rewrite it completely since it'll probably be broken again... Current version has at least the following errors: Mainline started using 2^14 (16384) byte requests when it was still the only client in existence; only the "official specification" still talked about the obsolete 32768 byte value which was in reality neither the default size nor maximum allowed. In version 4 the request behavior did not change, but the maximum allowed size did change to equal the default size. In latest mainline versions the max has changed to 32768 (note that this is the first appearance of 32768 for either default or max size since the first ancient versions). "Most older clients use 32KB requests" is false. Discussion of larger requests fails to take latency effects into account.

# piece: <len=0009+X><id=7><index><begin><block>
# The piece message is variable length, where X is the length of the block. The payload contains the following information:

# index: integer specifying the zero-based piece index
# begin: integer specifying the zero-based byte offset within the piece
# block: block of data, which is a subset of the piece specified by index.
# cancel: <len=0013><id=8><index><begin><length>
# The cancel message is fixed length, and is used to cancel block requests. The payload is identical to that of the "request" message. It is typically used during "End Game" (see the Algorithms section below).

# port: <len=0003><id=9><listen-port>
# The port message is sent by newer versions of the Mainline that implements a DHT tracker. The listen port is the port this peer's DHT node is listening on. This peer should be inserted in the local routing table (if DHT tracker is supported).
