extern crate rkdb;

#[allow(unused_imports)]
use rkdb::SYMBOLS;

fn main() {
    //TODO: While SYMBOLS is complete and correct, we can't set -Clink-args via buid.rs as of current Aug 18 nightly
    // currently hard coded in .cargo/config
    /*
    for s in SYMBOLS.iter() { ... }
    println!("cargo:rustc-env=RUSTFLAGS=-Clink-args=-Wl,-U,_krr")
    */
}
