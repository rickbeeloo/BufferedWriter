
using StringViews 

mutable struct Writer
    stream::IOStream 
    arr::Vector{UInt8}
    filled_till::Int
end 

function buffWriter(file::String; buffer_size::Int64=100_000)
    h = open(file, "w+")
    buffer = zeros(UInt8, buffer_size)
    return Writer(h, buffer, 0)
end

function _flush(writer::Writer)
    # Since we want text use a stringview 
    write(writer.stream, StringView(view(writer.arr, 1:writer.filled_till)))
end

function _write_to_buffer(writer::Writer, data::Vector{UInt8})
    @inbounds @simd for i in eachindex(data)
        writer.arr[writer.filled_till + i] = data[i]
    end 
end

function Base.write(writer::Writer, data::Vector{UInt8})
    # If not full copy to buffer 
    if writer.filled_till + length(data) <= length(writer.arr)
        # We still have space so copy
        _write_to_buffer(writer, data)
        writer.filled_till += length(data)
    else 
        # does it even fit in the buffer
        length(data) > length(writer.arr) && throw(ArgumentError("Increase buffer size"))

        # we have to flush to the file 
        _flush(writer)

        # We still have to write the data to the buffer
        writer.filled_till = 0
        _write_to_buffer(writer, data)
        writer.filled_till = length(data)
    end
end

function Base.close(writer::Writer)
    # flush array and close handle 
    _flush(writer)
    close(writer.stream)
end



