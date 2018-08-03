/ cargo build --release && /bin/cp -rf ./target/release/libkrshash.dylib /opt/q/m64/libkrshash.so && q krs-hash-bench.q

\l krs-hash.q

/ setting below will generate 3GB data
BYTES_MB:128

/ generate a string of up to x bytes out of numbers
make_str: { "" sv string x?9 }

/ 16b to 32kb data
sizes: {ceiling 2 xexp x} {[step;start;length] start+step*til length}[1;4;12]
mk_str: { a:{ [x;y] make_str x }[x;]; a each til ceiling BYTES_MB*1024*1024%x }

show "Making data for list using sizes..."
show sizes

data: { mk_str x } each sizes

show "Done"

gh: { 0x0 sv md5 x }; / md5 the content and make a GUID from it
as_mb: { ms:`long$`time$x; 1000f*BYTES_MB%`float$ms } / convert timings to MB/s

/ normal MD5+GUID creation
time_md5: { st:.z.p; gh each x; .z.p-st}

/ measure the Rust metro 128 performance (closest to MD5)
time_m128: { st:.z.p; rmetro128 each x; .z.p-st}

/ measure the Rust metro 64 performance
time_m64: { st:.z.p; rmetro64 each x; .z.p-st}

/ measure the Rust metro 128 performance on a list
time_m128_l: { st:.z.p; rmetro128 x; .z.p-st}

/ measure the Rust metro 64 performance on a list
time_m64_l: { st:.z.p; rmetro64 x; .z.p-st}

show "MD5+GUID (Q hash)"
res_md5: { time_md5 x } each data

show "METRO128 (Rust hash)"
res_m128: { time_m128 x } each data

show "METRO64 (Rust hash)"
res_m64: { time_m64 x } each data

show "METRO128 (Rust hash) on list"
res_m128_l: { time_m128_l x } each data

mbs_md5: as_mb each res_md5
mbs_m128: as_mb each res_m128
mbs_m64: as_mb each res_m64
mbs_m128_l: as_mb each res_m128_l

results:flip `SIZES`MD5`METRO128`METRO64`METRO128_LIST!(sizes;mbs_md5;mbs_m128;mbs_m64;mbs_m128_l)
show "Results in MB/s"
show results

show "Save results"
save `:memory_string_results.csv
