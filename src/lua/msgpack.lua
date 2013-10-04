-- msgpack.lua (internal file)

msgpack = {}
msgpack.encode = function(arg)
    return box.pack('p', arg)
end

msgpack.decode = function(arg)
    return box.unpack('p', arg)
end
