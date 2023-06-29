#![feature(box_patterns)]

extern crate fasthash;
extern crate rkdb;

use std::alloc::System;

#[global_allocator]
static A: System = System;

use rkdb::{k::*, kbindings::*, types::*};

use fasthash::{
    metro::{self, MetroHasher128_1, MetroHasher64_1},
    FastHasher, HasherExt,
};

use std::ffi::CStr;
use std::hash::Hasher;
use std::panic::catch_unwind;

#[no_mangle]
pub extern "C" fn kmetro64(k: *const K) -> *const K {
    catch_unwind(|| match KVal::new(k) {
        KVal::String(s) => metro64s(s),
        KVal::Symbol(KData::Atom(s)) => metro64sb(s),
        KVal::Symbol(KData::List(l)) => metrosl::<Metro64>(l),
        KVal::Dict(box ref k, box ref v) => metrokv::<Metro128>(k, v),
        _ => op_failed(k),
    })
    .or_else::<u8, _>(|_| Ok(op_panic()))
    .unwrap()
}

#[no_mangle]
pub extern "C" fn kmetro128(k: *const K) -> *const K {
    catch_unwind(|| match KVal::new(k) {
        KVal::String(s) => metro128s(s),
        KVal::Symbol(KData::Atom(s)) => metro128sb(s),
        KVal::Symbol(KData::List(l)) => metrosl::<Metro128>(l),
        KVal::Mixed(l) => metro128ml(l.as_slice()), // retained as a curiosity
        KVal::Dict(box ref k, box ref v) => metrokv::<Metro128>(k, v),
        _ => op_failed(k),
    })
    .or_else::<u8, _>(|_| Ok(op_panic()))
    .unwrap()
}

#[inline]
fn op_failed(k: *const K) -> *const K {
    unsafe { kerror(&format!("nyi-{}", (*k).t)) }
}

#[inline]
fn op_panic() -> *const K {
    kerror("rust-panic")
}

#[inline]
fn value_error() -> *const K {
    kerror("rust-value")
}

trait Backend {
    type Hasher: Hasher;

    fn new_hash() -> Self::Hasher;
    fn new_list(len: usize) -> *const K;
    fn hash_into(bytes: &[u8], dest: *mut u8) -> isize;
    fn finish(h: Self::Hasher) -> *const K;

    fn accumulate(h: &mut Self::Hasher, lt: &[*const i8]) {
        for t in lt.iter() {
            let bytes = unsafe { CStr::from_ptr(*t).to_bytes() };
            h.write(bytes);
        }
    }
}

struct Metro64;
struct Metro128;

impl Backend for Metro64 {
    type Hasher = MetroHasher64_1;

    #[inline]
    fn new_hash() -> Self::Hasher {
        Self::Hasher::new()
    }

    #[inline]
    fn new_list(len: usize) -> *const K {
        unsafe { ktn(7, len as i64) }
    }

    #[inline]
    fn hash_into(bytes: &[u8], dest: *mut u8) -> isize {
        let g = metro::hash64(&bytes).to_ne_bytes();
        unsafe { std::ptr::copy_nonoverlapping(g.as_ptr(), dest, g.len()) };
        g.len() as isize
    }

    #[inline]
    fn finish(h: Self::Hasher) -> *const K {
        klong(h.finish() as J)
    }
}

impl Backend for Metro128 {
    type Hasher = MetroHasher128_1;

    #[inline]
    fn new_hash() -> Self::Hasher {
        Self::Hasher::new()
    }

    #[inline]
    fn new_list(len: usize) -> *const K {
        unsafe { ktn(2, len as i64) }
    }

    #[inline]
    fn hash_into(bytes: &[u8], dest: *mut u8) -> isize {
        let g = metro::hash128(&bytes).to_ne_bytes();
        unsafe { std::ptr::copy_nonoverlapping(g.as_ptr(), dest, g.len()) };
        g.len() as isize
    }

    #[inline]
    fn finish(h: Self::Hasher) -> *const K {
        let g = h.finish_ext().to_ne_bytes();
        unsafe { ku(U { g }) }
    }
}

#[inline]
fn metro64s(t: &str) -> *const K {
    klong(metro::hash64(&t) as J)
}

// 128bit ops generate GUIDs
#[inline]
fn metro128s(t: &str) -> *const K {
    let g = metro::hash128(&t).to_ne_bytes();
    unsafe { ku(U { g }) }
}

#[inline]
fn metro64sb(t: &*const i8) -> *const K {
    let bytes = unsafe { CStr::from_ptr(*t).to_bytes() };
    klong(metro::hash64(&bytes) as J)
}

#[inline]
fn metro128sb(t: &*const i8) -> *const K {
    let bytes = unsafe { CStr::from_ptr(*t).to_bytes() };
    let g = metro::hash128(&bytes).to_ne_bytes();
    unsafe { ku(U { g }) }
}

#[inline]
fn metrosl<T: Backend>(lt: &[*const i8]) -> *const K {
    let k = T::new_list(lt.len()); // list of longs
    let kx = unsafe { (*k).fetch_slice::<u8>().as_mut_ptr() };
    let mut i = 0;

    for t in lt.iter() {
        unsafe {
            let bytes = CStr::from_ptr(*t).to_bytes();
            i += T::hash_into(bytes, kx.offset(i));
        }
    }

    k
}

#[inline]
fn metrokv<T: Backend>(k: &KVal, v: &KVal) -> *const K {
    let mut hash = T::new_hash();

    if let KVal::Symbol(KData::List(l)) = k {
        T::accumulate(&mut hash, l);
    } else {
        return value_error();
    }

    match v {
        KVal::Symbol(KData::List(l)) => {
            T::accumulate(&mut hash, l);
        }
        KVal::Mixed(l) => {
            for i in l.iter() {
                match i {
                    KVal::String(s) => {
                        hash.write(s.as_bytes());
                    }
                    KVal::Symbol(KData::Atom(s)) => {
                        let bytes = unsafe { CStr::from_ptr(**s).to_bytes() };
                        hash.write(bytes);
                    }
                    _ => return value_error(),
                };
            }
        }
        _ => return value_error(),
    }

    T::finish(hash)
}

// retained as a curiosity, performance is good for small lists
// but degrades due to wrapper allocations as size increases
#[inline]
fn metro128ml(lt: &[KVal]) -> *const K {
    let k = Metro128::new_list(lt.len());
    let kx = unsafe { (*k).fetch_slice::<u8>().as_mut_ptr() };
    let mut i = 0;

    for t in lt.iter() {
        let bytes = match t {
            KVal::String(s) => s.as_bytes(),
            KVal::Symbol(KData::Atom(s)) => unsafe { CStr::from_ptr(**s).to_bytes() },
            _ => return value_error(),
        };

        i += unsafe { Metro128::hash_into(bytes, kx.offset(i)) };
    }

    k
}
