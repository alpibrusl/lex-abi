# Tests for the Ethereum ABI encoder, using the official Solidity ABI spec's
# worked example vectors. Each case returns Result[Unit, Str]; a failed case
# fails via a forced runtime error, and run_all collects them all.

import "std.bytes" as bytes

import "std.list" as list

import "../src/abi" as abi

fn expect_str(actual :: Str, expected :: Str, what :: Str) -> Result[Unit, Str] {
  if actual == expected {
    Ok(())
  } else {
    Err(what + ": expected " + expected + " got " + actual)
  }
}

# VECTOR 1 ? baz(uint32, bool) called with (69, true).
fn v1() -> Result[Unit, Str] {
  let got := abi.to_hex(abi.encode_call("baz(uint32,bool)", [abi.AUint(69), abi.ABool(true)]))
  let want := "cdcd77c000000000000000000000000000000000000000000000000000000000000000450000000000000000000000000000000000000000000000000000000000000001"
  expect_str(got, want, "vector 1")
}

# VECTOR 2 ? sam(bytes, bool, uint256[]) called with ("dave", true, [1,2,3]).
fn v2() -> Result[Unit, Str] {
  let got := abi.to_hex(abi.encode_call("sam(bytes,bool,uint256[])", [abi.ADynBytes(bytes.from_str("dave")), abi.ABool(true), abi.AUintArray([1, 2, 3])]))
  let want := "a5643bf20000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000464617665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003"
  expect_str(got, want, "vector 2")
}

# VECTOR 3 ? f(uint256, uint32[], bytes10, bytes) called with
# (0x123, [0x456, 0x789], "1234567890", "Hello, world!").
fn v3() -> Result[Unit, Str] {
  let got := abi.to_hex(abi.encode_call("f(uint256,uint32[],bytes10,bytes)", [abi.AUint(291), abi.AUintArray([1110, 1929]), abi.ABytesN(bytes.from_str("1234567890"), 10), abi.ADynBytes(bytes.from_str("Hello, world!"))]))
  let want := "8be6524600000000000000000000000000000000000000000000000000000000000001230000000000000000000000000000000000000000000000000000000000000080313233343536373839300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000004560000000000000000000000000000000000000000000000000000000000000789000000000000000000000000000000000000000000000000000000000000000d48656c6c6f2c20776f726c642100000000000000000000000000000000000000"
  expect_str(got, want, "vector 3")
}

# VECTOR 4 ? the ERC-20 transfer selector.
fn v4() -> Result[Unit, Str] {
  let got := abi.to_hex(abi.selector("transfer(address,uint256)"))
  expect_str(got, "a9059cbb", "vector 4")
}

# encode([]) returns empty bytes.
fn empty_encode() -> Result[Unit, Str] {
  let got := abi.to_hex(abi.encode([]))
  expect_str(got, "", "empty encode")
}

# encode_call on a zero-argument function returns exactly the 4-byte selector.
fn zero_arg_call() -> Result[Unit, Str] {
  let got := abi.to_hex(abi.encode_call("foo()", []))
  let want := abi.to_hex(abi.selector("foo()"))
  expect_str(got, want, "zero-arg call")
}

fn is_err(r :: Result[Unit, Str]) -> Bool {
  match r {
    Ok(_) => false,
    Err(_) => true,
  }
}

fn run_all() -> Unit {
  let results := [v1(), v2(), v3(), v4(), empty_encode(), zero_arg_call()]
  let failed := list.filter(results, is_err)
  if list.len(failed) == 0 {
    ()
  } else {
    let __force_failure := 1 / 0
    ()
  }
}

