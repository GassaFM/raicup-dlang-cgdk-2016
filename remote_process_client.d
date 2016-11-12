module remote_process_client;

import std.bitmanip;
import std.conv;
import std.exception;
import std.range;
import std.socket;
import std.stdio;
import std.traits;

import model;

enum MessageType : byte
{
    unknownMessage,
    gameOver,
    authenticationToken,
    teamSize,
    protocolVersion,
    gameContext,
    playerContext,
    moveMessage,
}

class RemoteProcessClient
{
public:
    this (string host, string port)
    {
        Address addr = getAddress (host, port)[0];
        socket = new Socket (addr.addressFamily, SocketType.STREAM);
        socket.setOption (SocketOptionLevel.TCP,
            SocketOption.TCP_NODELAY, true);
        socket.setOption (SocketOptionLevel.SOCKET,
            SocketOption.RCVBUF, 1 << 12);
        socket.connect (addr);
    }

    void writeToken (string token)
    {
        write (MessageType.authenticationToken);
        write (token);
    }

    int readTeamSize ()
    {
        enforce (read !(MessageType) == MessageType.teamSize);
        return read !(int);
    }
    
    void writeProtocolVersion ()
    {
        write (MessageType.protocolVersion);
        write !(int) (2);
    }

    auto readGameContextMessage ()
    {
        auto messageType = read !(MessageType) ();
        enforce (messageType == MessageType.gameContext);

        return read !(immutable Game) ();
    }

    auto readPlayerContextMessage ()
    {
        auto messageType = read !(MessageType) ();
        if (messageType == MessageType.gameOver)
        {
            return null;
        }
        enforce (messageType == MessageType.playerContext);

        return read !(immutable PlayerContext) ();
    }

    void writeMovesMessage (Move [] moves)
    {
        write (MessageType.moveMessage);

        write !(Move []) (moves);
    }

    void close ()
    {
        socket.close;
    }

private:
    Socket socket;

    auto read (T) ()
        if (is (T == class))
    {
        enforce (read !(bool));

        return new immutable T ();

        // TODO: reflect on constructor of T to get field types and names.
        // Alternatively, just generate individual functions in java_to_d.d.
/*
        auto wizards = read !(immutable Wizard []) ();
        auto world = read !(immutable World) ();

        return new immutable T (wizards, world);
*/
    }

    void write (T) (T t)
        if (is (T == class))
    {
        write !(bool) (true);

        // TODO: reflect on constructor of T to get field types and names.
        // Alternatively, just generate individual functions in java_to_d.d.
    }

    auto read (T : T [num], ulong num) ()
    {
        int len = read !(int) ();
        enforce (len == num);

        T [num] ret = void;
        foreach (ref val; ret)
        {
            val = read !(T) ();
        }
        return ret;
    }

    auto read (T : string) ()
    {
        int len = read !(int) ();
        enforce (len >= 0);
        return cast (string) (readBytesRuntime (len).idup);
    }

    void write (T : string) (T value)
    {
        write !(int) (cast (int) (value.length));
        writeBytes (cast (ubyte []) value);
    }

    auto read (T : T []) ()
    {
        debug (io) {writeln ("array read");}
        int len = read !(int) ();
        enforce (len >= 0);

        T [] ret;
        ret.reserve (len);
        foreach (i; 0..len)
        {
            ret ~= read !(T) ();
        }

        return ret;
    }

    void write (T : T []) (T [] value)
    {
        write !(int) (cast (int) (value.length));
        foreach (elem; value)
        {
            write !(T) (elem);
        }
    }

    auto read (T) ()
        if (!is (T == class))
    {
        return littleEndianToNative !(T) (readBytes !(T.sizeof));
    }

    void write (T) (T value)
        if (!is (T == class))
    {
        writeBytes (nativeToLittleEndian (value));
    }

    auto readBytes (size_t byteCount) ()
    {
        ubyte [byteCount] bytes = readBytesRuntime (byteCount);
        return bytes;
    }

    auto readBytesRuntime (size_t byteCount)
    {
        auto bytes = new ubyte [byteCount];
        size_t offset = 0;
        while (offset < byteCount)
        {
            debug (io) {writeln ("in ", offset, " ", byteCount);}
            offset += socket.receive (bytes[offset..bytes.length]);
        }
        debug (io) {writeln ("read: ", bytes);}
        return bytes;
    }

    void writeBytes (const ubyte [] bytes)
    {
        size_t offset = 0;
        while (offset < bytes.length)
        {
            auto sent = socket.send (bytes);
            enforce (sent > 0);
            offset += sent;
        }
        debug (io) {writeln ("write: ", bytes);}
    }
}
