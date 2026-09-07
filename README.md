# lex-abi

Ethereum ABI (contract call) encoding for the [Lex](https://lexlang.org) language.

Encode-only: builds calldata (function selector + head/tail-encoded
arguments) per the [Solidity ABI specification](https://docs.soliditylang.org/en/latest/abi-spec.html).
No decoding, no dynamic type schemas beyond what's needed to encode a
known argument list.
