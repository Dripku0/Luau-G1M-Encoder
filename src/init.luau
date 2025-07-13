local fs = require("@lune/fs")
local stdio = require("@lune/stdio")

local writeu32 = buffer.writeu32
local writeu16 = buffer.writeu16
local writeu8 = buffer.writeu8
local writestring = buffer.writestring
local band = bit32.band
local bxor = bit32.bxor
local byteswap = bit32.byteswap

local HEADER = {0xAAACBDAF, 0x90889A8D}

local UNKNOWN = {
    byteswap(0xFFEFFFEF), -- @0x09
    0xFF,       -- @0x0D
    0xFE,       -- @0x0F
    1,          -- @0x33
    1,          -- @0x44
    0xFEFF      -- @0x1E
}

local FILE_VERSION = 0xCE

local function writeu64(buffer_: buffer, position: number, u32: { number})
    buffer.writeu32(buffer_, position, byteswap(u32[1]))
    buffer.writeu32(buffer_, position + 4, byteswap(u32[2]))
end

--[=[
    Writes the header to the buffer at @0x00.

    @param out The buffer to write to.
    @param signature A table containing two 32-bit unsigned integers representing the signature.
    @param version The version number to write.
    @param program_size The size of the program to write.
    @return nil
]=]
local function writeHeader(out: buffer, signature: { number }, version: number, program_size: number)
    writeu64(out, 0x00, signature)
    writeu8(out, 0x08, version)

    -- Integrity 1: Calculated as (0x72 - @0x48) & 0xFF
    writeu8(out, 0x0E, band(0x72 - program_size, 0xFF))
end

--[=[
    Writes unknown data to the buffer at a specific position.
    This function writes a fixed pattern of bytes to the output buffer.

    @param out The buffer to write to.
    @return nil
]=]
local function writeUnknown(out: buffer)
    writeu32(out, 0x09, UNKNOWN[1])
    writeu8(out, 0x0D, UNKNOWN[2])
    writeu32(out, 0x0F, UNKNOWN[3])
    writeu8(out, 0x33, UNKNOWN[4])
    writeu32(out, 0x44, UNKNOWN[5])
    writeu16(out, 0x1E, UNKNOWN[6])
end

--[=[
    Writes metadata to the output buffer at a specific position.
    This function writes metadata such as file size, program size, and other
    information to the output buffer.

    @param name The name of the program.
    @param out The buffer to write to.
    @param file_size The size of the file.
    @param program_size The size of the program.
    @return nil
]=]
local function writeMetadata(name: string, out: buffer, file_size: number, program_size: number)
    local occupied_size = byteswap(bxor(file_size, 0xFFFFFFFF))

    writeu32(out, 0x10, occupied_size)
    
    -- Integrity 2: Calculated as ((@0x10 & 0xFF) + 0x48) & 0xFF
    writeu8(out, 0x14, band(band(byteswap(occupied_size), 0xFF) + 0x48, 0xFF))
    
    writestring(out, 0x20, "PROGRAM")
    writestring(out, 0x34, "system")
    writestring(out, 0x3C, name)

    writeu32(out, 0x48, program_size)
end

--[=[
    Encodes a program into the g1m format.
    This function takes a name and a program string, and encodes them into a
    buffer with the specified header, metadata, and program content.

    @param name The name of the program (max 8 characters).
    @param program The program content as a string.
    @return A buffer containing the encoded program.
]=]
local function encode(name: string, program: string)
    assert(#name <= 8, "Name must be 8 characters or less")

    local program_size = #program
    local end_bytes = 4 - ((program_size + 0x0A) % 4)

    local output = buffer.create(program_size + 0x56 + end_bytes)

    writeHeader(output, HEADER, FILE_VERSION, program_size + 0x0A + end_bytes)
    writeUnknown(output)
    writeMetadata(name, output, buffer.len(output), program_size + 0x0A + end_bytes)
    writestring(output, 0x56, program)

    return output
end

local files = fs.readDir("inputs")
local name = stdio.prompt("text", "Enter the name of the program (max 8 characters):")
local program = stdio.prompt("select", "Enter the program: ", files)

local output = encode(name, fs.readFile(`inputs/{files[program]}`))

fs.writeFile("out.g1m", output)

print(`Successfully encoded the program "{files[program]}" to "out.g1m"`)