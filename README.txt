Session Description Protocol parser under permissive license. It's
goal is to be as simple and dumb as possible.

To build it you need Ragel state machine compiler [1] and (possibly)
CMake. To build without CMake, do something like this:

$ ragel -o osdp.c osdp.rl
$ gcc -o osdp.o -c osdp.c

And link osdp.o to your project. There is example.c to give you a
clue about the intended usage. Yes, it uses static input buffer of
fixed size to keep things simple.

[1] http://www.complang.org/ragel/
