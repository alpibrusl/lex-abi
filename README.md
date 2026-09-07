# lex-abi

**Part of the [Lex](https://lexlang.org) project** — [Manifesto](https://www.lexlang.org/manifesto) · [All packages](https://lexlang.org)

Ethereum ABI (contract call) encoding for the Lex language — the calldata
format every smart-contract call and transaction argument list uses,
in pure Lex on top of `std.bytes`/`std.crypto`.

```
import "lex-abi/abi" as abi

abi.to_hex(abi.selector("transfer(address,uint256)"))
# -> "a9059cbb"

abi.to_hex(abi.encode_call("baz(uint32,bool)", [abi.AUint(69), abi.ABool(true)]))
# -> "cdcd77c0" + two 32-byte words (69, then true)
```

## Why it exists

With `secp256k1`/`keccak256` in `std.crypto` and RLP encoding already
covered by [lex-rlp](https://github.com/alpibrusl/lex-rlp), ABI encoding
was the missing piece for actually building a contract call from Lex — the
function selector and argument encoding that becomes a transaction's
`data` field. This package is exactly that: encode-only, no decoding, no
type-schema parsing beyond a known argument list.

## API

- `type AbiValue = AUint(Int) | ABool(Bool) | ABytesN(Bytes, Int) | ADynBytes(Bytes) | AString(Str) | AUintArray(List[Int])` — a value going into a call's argument list. `AUint`/`ABool`/`ABytesN` are static (encoded inline); `ADynBytes`/`AString`/`AUintArray` are dynamic (encoded via a head offset + tail body).
- `selector(signature) -> Bytes` — the 4-byte function selector: first 4 bytes of `keccak256` of the ASCII signature.
- `encode(values) -> Bytes` — head/tail ABI encoding of a value list.
- `encode_call(signature, values) -> Bytes` — `selector(signature) ++ encode(values)`, i.e. full calldata.
- `to_hex(data) -> Str` — hex convenience wrapper.

No signed integers, no tuples, no nested arrays — just enough to encode a
flat argument list correctly.

## Tested against

The official [Solidity ABI specification](https://docs.soliditylang.org/en/latest/abi-spec.html)'s
own worked examples: `baz(uint32,bool)`, `sam(bytes,bool,uint256[])`,
`f(uint256,uint32[],bytes10,bytes)` — plus the well-known ERC-20
`transfer(address,uint256)` selector, an empty argument list, and a
zero-argument call. See `tests/test_abi.lex`.

## Provenance

Written by [`lex-code`](https://github.com/alpibrusl/lex-code) driving a
local `qwen3.8:27b-mlx` model over LiteLLM, supervised by Claude (Sonnet
5). The first automated pass correctly diagnosed the test-file setup but
left a real bug unfixed (a list-accumulator step that overwrote instead
of appended, breaking any multi-argument call); a second, more targeted
round — naming the exact function and the exact mechanism — fixed it
correctly. Every vector below was independently re-verified against the
Solidity spec's own hex output before this was pushed, including two
transcription typos in the test file's own hand-typed hex strings, caught
by rebuilding the expected values from the individual 32-byte words
rather than trusting one long hand-typed string.
