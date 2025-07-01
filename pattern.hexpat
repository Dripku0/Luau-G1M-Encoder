#include "std/io.pat"

fn inv32(auto v) {
    return ~v & 0xFFFFFFFF;
};

fn inv16(auto v) {
    return ~v & 0xFFFF;
};

struct G1M {
    u64 signature [[ name("G1M Signature") ]];
    u8 file_version [[ name("File Version") ]];
    u8 unk_00[5] [[ hidden, color("000000") ]];

    u8 integrity_0 [[ 
        name("Integrity Byte 1"),
        comment("Calculated as:\n(0x72 - @0x48) & 0xFF") 
    ]]; // Calculated as (0x72 - @0x48) & 0xFF
    
    u8 unk_01 [[ hidden, color("000000") ]];;

    be u32 file_size [[ 
        name("File Size"), 
        format("inv32")     
    ]]; // Inverted 32-bit file size

    
    u8 integrity_1 [[ 
        name("Integrity Byte 2"),
        comment("Calculated as:\n((@0x10 & 0xFF) + 0x48) & 0xFF") 
    ]]; // Calculated as ((@0x10 & 0xFF) + 0x48) & 0xFF

    u8 paddingb_0[9] [[ hidden, color("000000") ]];

    be u16 unk_02 [[ hidden, format("inv16") ]];

    char hdr_0[7] [[ name("PROGRAM Chunk") ]];
    u8 paddingb_1[9] [[ hidden, color("000000") ]];

    be u32 unk_03 [[hidden]];

    char hdr_1[6] [[ name("system Chunk") ]];
    u8 paddingb_2[2] [[ hidden, color("000000") ]];

    char name[8] [[ name("Program Name") ]];

    u32 unk_04 [[ hidden, color("000000") ]];
    u32 size [[ name("Program size") ]];

    u8 program_padding[10];
    u8 program[size - 10];
};

G1M File @ 0x0;

std::print("Integrity byte 1 calculated as: {}", (0x72 - File.size) & 0xFF);
std::print("Integrity byte 2 calculated as: {}\n", ((File.file_size & 0xFF) + 0x48) & 0xFF);