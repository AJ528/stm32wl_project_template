#!/bin/bash

echo "START debug.bat"
~/git_repos/stlink/build/Release/bin/st-util -p 61234 &

gdb-multiarch -ex "set confirm off" -ex "target remote *:61234" \
    -ex "load" -ex "break main" -ex "tui enable" bin/output.elf

echo "DONE"
