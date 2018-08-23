# kdb-rs-hash

Implement a Rust binding for hashing using Metro hash with CRC intrinsics supporting > 10GB/s hash rates on a single modern i5/i7 x86 core.

Review the write up at [Rust, meet Q](https://blog.redsift.com/labs/rust-meet-q/).

## Build & Run

Note that this library requires a nightly rust and as been built on `rust version 1.30.0-nightly (33b923fd4 2018-08-18)`. **If you see errors related to `to_ne_bytes` not being defined or the like, you need to rustup to the currently nightly.**

```
# create ./target/release/libkrshash.so 
$ cargo build --release

# NOTE: place libkrshash.so in your library path or next to your q binary
$ q krs-hash.q
KDB+ 3.6 2018.06.14 Copyright (C) 1993-2018 Kx Systems
m64/ 12()core 16384MB

q)rmetro128 `hello
fec3012b-5c96-d2f1-f8dd-32a0b77bfbe5
q)rmetro128 "hello"
fec3012b-5c96-d2f1-f8dd-32a0b77bfbe5
```

## Measure performance using in memory and persisted data

```
$ q krs-hash-dict-bench.q 
```

## OS-X notes

The target build a dylib that is 'weak linked', i.e. the kdb+ symbols are left undefined as the library is meant for inclusion in a running Q process.

For inclusion into the Q process, this can be renamed to `.so`. e.g.

```
$ cargo build --release && /bin/cp -rf ./target/release/libkrshash.dylib /opt/q/m64/libkrshash.so
$ q krs-hash.q
```

## Benchmarking files
 * `krs-hash.q`: Includes Rust MetroHash bindings.
 * `krs-hash-unit.q`: q unit tests for binding.
 * `krs-hash-str-bench.q`: Benchmark test for hashes on strings.
 * `krs-hash-dict-bench.q`: Benchmark test for in-memory and mapped hashes on dictionaries.
 * `krs-hash-dict-bench-func.q`: q functions to compute benchmark test results.
