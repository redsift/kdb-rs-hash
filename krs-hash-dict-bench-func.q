// Functions to calculate and record in-memory and mapped speeds of hashing on dictionaries
// Takes input of rows (of table) and data_size (of dictionary values) to create a table of dictionaries of required size

dict_speed_test:{[rows;data_size;tab_tag]
    show "Generating table of data"
    dict_keys:4;
    tab:([] data:(`$/:dict_keys#.Q.a)(!)/:dict_keys cut data_size cut (rows*dict_keys*data_size)?" "); / generate a table of data
    (get "`:tab/",(first string tab_tag),"/") set tab; / Save table to disk
    show "Table of generated of size(MB)";
    show tab_size:%[;1024*1024] sum hcount each `$(":tab/",(first string tab_tag),"/data";":tab/",(first string tab_tag),"/data#";":tab/",(first string tab_tag),"/data##"); / calculate size of table in megabytes
    show "Dictionary size in bytes";
    show dict_size:1024*1024*tab_size%count tab; / size of each dict in bytes 
    dict_sizes,:dict_size;

    data_ready::"=" sv 'flip((tab`data)[;`a];(tab`data)[;`b];(tab`data)[;`c];(tab`data)[;`d]); / prepare data for hashing
    data_ready_size:(sum count each data_ready)%(1024*1024); / calculate size of data to use in speed calculations

    gh:: { 0x0 sv md5 x };

    show "Measuring in-memory speeds";
    time_md5:system"t gh each data_ready"; / uses q timer \t (equivalent to calling system"t")
    show "MD5+GUID";
    show speed_md5,:1000f*data_ready_size%time_md5; / size of the data to be hashed in mb over time

    time_m128: system"t rmetro128 each data_ready";
    show "METRO128";
    show speed_m128,:1000f*data_ready_size%time_m128;

    time_m64: system"t rmetro64 each data_ready";
    show "METRO64";
    show speed_m64,:1000f*data_ready_size%time_m64;
    show "In-memory speeds completed";
    .Q.gc[]; / garbage collect to free up OS memory
 }

dict_mapped_speed_test:{
    tab_tag::x;
    show "Loading in data of table";
    show string tab_tag;
    system"l tab/",(first string tab_tag);
    show "Preparing and saving data";
    data_ready::{[tab_tag] "=" sv 'flip(((get first string tab_tag)`data)[;`a];((get first string tab_tag)`data)[;`b];((get first string tab_tag)`data)[;`c];((get first string tab_tag)`data)[;`d])};
    dr::data_ready[tab_tag];
    save `dr;
    show "Data saved";

    gh::{ 0x0 sv md5 x };

    show "Removing data from memory";
    delete dr from `.; / remove mapping to data
    ![`.;();0b;tables[]]; / remove mapping to table

    show "Measuring mapped speeds of table";
    show string tab_tag;
    /mapped_time_md5:system"t gh each dr:data_ready[tab_tag]";
    mapped_time_md5:system"t gh each get load`dr";
    data_ready_size:(sum count each dr)%(1024*1024);
    show "MD5+GUID"
    show mapped_speed_md5,:1000f*data_ready_size%mapped_time_md5; / size of the data to be hashed in mb over time
    .Q.gc[]; / garbage collect for md5

    delete dr from `.; / unmap
    mapped_time_m128:system"t rmetro128 each get load`dr";
    data_ready_size:(sum count each dr)%(1024*1024);
    show "M128"
    show mapped_speed_m128,:1000f*data_ready_size%mapped_time_m128; / size of the data to be hashed in mb over time
    .Q.gc[]; / garbage collect for m128

    delete dr from `.; / unmap
    mapped_time_m64:system"t rmetro64 each get load`dr";
    data_ready_size:(sum count each dr)%(1024*1024);
    show "M64"
    show mapped_speed_m64,:1000f*data_ready_size%mapped_time_m64; / size of the data to be hashed in mb over time
    .Q.gc[]; / garbage collect for m64

    system"rm dr";
    system"rm dr#";
 }

