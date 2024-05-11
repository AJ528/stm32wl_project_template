#!/bin/bash

# this bash script is called by "make debug"

echo "START debug.bat"
# call st-util to start the gdb server and listen on port 61234
st-util -p 61234 &

# start the gdb client, connect to the remote server, load the program onto
# the target, set a breakpoint at main, and enable the text user interface
# also disable confirmations so you can quit by just using "q"
gdb-multiarch -ex "set confirm off" -ex "target remote *:61234" \
    -ex "load" -ex "break main" -ex "tui enable" bin/output.elf

echo "DONE"
