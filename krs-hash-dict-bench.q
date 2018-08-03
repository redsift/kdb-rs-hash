\l krs-hash.q
\l krs-hash-dict-bench-func.q


/ The following generates 8 tables of around 500mb with dictionary entries of roughly 128bytes to 16kilobytes

rows:(5000000;2500000;1000000;500000;250000;150000;75000;35000) 
data_size_vec:(1;30;95;200;450;965;1975;4000) 
tab_tags:`$/:(count rows)#.Q.a

{dict_speed_test[x;y;z]} ./: rows,'data_size_vec,'tab_tags; / in-memory 
.Q.gc[]
{dict_mapped_speed_test[x]} each tab_tags; / mapped

show "Results of speed of dictionary sizes when in-memory"
show memory_dict_results:([]sizes:dict_sizes;MD5:speed_md5;M128:speed_m128;M64:speed_m64) 
save `:memory_dict_results.csv
show "Results of speed of dictionary sizes when mapped"
show mapped_dict_results:([]sizes:dict_sizes;MD5:mapped_speed_md5;M128:mapped_speed_m128;M64:mapped_speed_m64)
save `:mapped_dict_results.csv

\\ 
