# Ethereum ABI (contract call) encoding ? encode-only.
#
# Builds calldata (4-byte function selector + head/tail-encoded arguments) per
# the official Solidity ABI specification. No decoding.

import "std.crypto" as crypto

import "std.bytes" as bytes

import "std.list" as list

# The set of ABI values this encoder can produce. AUint/ABool/ABytesN are static;
# ADynBytes/AString/AUintArray are dynamic.
type AbiValue = AUint(Int) | ABool(Bool) | ABytesN((Bytes, Int)) | ADynBytes(Bytes) | AString(Str) | AUintArray(List[Int])

fn is_static(v :: AbiValue) -> Bool {
  match v {
    AUint(_n) => true,
    ABool(_b) => true,
    ABytesN(_b, _n) => true,
    ADynBytes(_b) => false,
    AString(_s) => false,
    AUintArray(_xs) => false,
  }
}

# Collect the big-endian (most-significant-first) byte chunks of a non-negative
# integer, without any padding.
fn u_bytes(n :: Int, acc :: List[Bytes]) -> List[Bytes] {
  if n == 0 {
    acc
  } else {
    u_bytes(n / 256, list.concat([bytes.u8(n % 256)], acc))
  }
}

# Build a 32-byte big-endian word for a non-negative integer, left zero-padded.
fn u_word(n :: Int) -> Bytes {
  let body := u_bytes(n, [])
  let zeros := bytes.concat_all(list.map(list.range(0, 32 - list.len(body)), fn (__zero :: Int) -> Bytes {
    bytes.u8(0)
  }))
  bytes.concat(zeros, bytes.concat_all(body))
}

# Pad a run of raw bytes on the right with zeros up to the next multiple of 32
# bytes. A non-empty input always rounds up to at least 32 bytes; empty input
# stays empty (its caller supplies a 32-byte length word of its own).
fn pad32(b :: Bytes) -> Bytes {
  let len := bytes.len(b)
  let total := (len + 31) / 32 * 32
  if total == len {
    b
  } else {
    bytes.concat(b, bytes.concat_all(list.map(list.range(0, total - len), fn (__lex_discard_1 :: Int) -> Bytes {
      bytes.u8(0)
    })))
  }
}

# Encode a single value's own bytes: a static word, or a dynamic value's body
# (length/payload) without its head offset.
fn encode_value(v :: AbiValue) -> Bytes {
  match v {
    AUint(n) => u_word(n),
    ABool(b) => u_word(if b {
      1
    } else {
      0
    }),
    ABytesN(raw, _n) => pad32(raw),
    ADynBytes(raw) => bytes.concat(u_word(bytes.len(raw)), pad32(raw)),
    AString(s) => {
      let raw := bytes.from_str(s)
      bytes.concat(u_word(bytes.len(raw)), pad32(raw))
    },
    AUintArray(xs) => bytes.concat(u_word(list.len(xs)), bytes.concat_all(list.map(xs, u_word))),
  }
}

# Head/tail encoding of a list of top-level values.
#
# The head is 32 bytes per value, in order. A static value's head word IS its
# encoding. A dynamic value's head word is a big-endian byte offset measured from
# the start of this head+tail area to its own body in the tail; the tail holds
# each dynamic value's body, in the same order as the values that reference it,
# concatenated back-to-back.
type Accum = { heads :: List[Bytes], tails :: List[Bytes], pos :: Int }

fn encode_acc(v :: AbiValue, head_size :: Int, acc :: Accum) -> Accum {
  if is_static(v) {
    { heads: list.concat(acc.heads, [encode_value(v)]), tails: acc.tails, pos: acc.pos }
  } else {
    let body := encode_value(v)
    { heads: list.concat(acc.heads, [u_word(head_size + acc.pos)]), tails: list.concat(acc.tails, [body]), pos: acc.pos + bytes.len(body) }
  }
}

fn encode(values :: List[AbiValue]) -> Bytes {
  let head_size := list.len(values) * 32
  let acc := list.fold(values, { heads: [], tails: [], pos: 0 }, fn (a :: Accum, v :: AbiValue) -> Accum {
    encode_acc(v, head_size, a)
  })
  bytes.concat(bytes.concat_all(acc.heads), bytes.concat_all(acc.tails))
}

# The 4-byte function selector: first 4 bytes of keccak256(signature).
fn selector(signature :: Str) -> Bytes {
  bytes.slice(crypto.keccak256(bytes.from_str(signature)), 0, 4)
}

# Complete calldata for a contract call: selector followed by the encoded args.
fn encode_call(signature :: Str, values :: List[AbiValue]) -> Bytes {
  bytes.concat(selector(signature), encode(values))
}

# Thin wrapper over std.crypto.hex_encode.
fn to_hex(data :: Bytes) -> Str
  examples {
    to_hex(bytes.slice(bytes.u8(0), 0, 0)) => "",
    to_hex(bytes.from_str("dave")) => "64617665"
  }
{
  crypto.hex_encode(data)
}

