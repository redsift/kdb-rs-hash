\l krs-hash.q

\c 60 100

test_str_63:"012345678901234567890123456789012345678901234567890123456789012"
test_str_63_l: (test_str_63;test_str_63;test_str_63) 
test_str_63_l1: enlist test_str_63 

test_sym_63:`$test_str_63
test_sym_63_l: (test_sym_63;test_sym_63;test_sym_63) / 11h
test_sym_63_l1: enlist test_sym_63 / 11h

test_sym_dict_unit:(enlist `hello)!(enlist `world) / 168124756093089300765778527570074281113
test_str_dict:`key1`key2!("value1";"value2")
test_sym_dict:`key1`key2!(`value1;`value2)
test_mix_dict:`key1`key2!("value1";`value2)

test_128crc_1:"G"$"b329ed67-8316-04d3-dfac-4e4876d8262f"

do64: { show type x; res_64: rmetro64 x; show res_64; show type res_64; }
do128: { show type x; res_128: rmetro128 x; show res_128; show type res_128; }

do64[test_str_63]

res_128crc_str_1: rmetro128 test_str_63
$[test_128crc_1=res_128crc_str_1; res_128crc_str_1; exit -1]
show type res_128crc_str_1

res_128crc_sym_1: rmetro128 test_sym_63
$[test_128crc_1=res_128crc_sym_1; res_128crc_sym_1; exit -1]
show type res_128crc_sym_1

do64[test_sym_63_l1]
do64[test_sym_63_l]

do128[test_str_63_l1]
do128[test_str_63_l]

do128[test_sym_63_l1]
do128[test_sym_63_l]

show "64 bit dict value"
do64[test_sym_dict_unit]
do64[test_sym_dict]
do64[test_str_dict]
do64[test_mix_dict]

show "128 bit dict value"
do128[test_sym_dict_unit]
do128[test_sym_dict]
do128[test_str_dict]
do128[test_mix_dict]

/ exit 0