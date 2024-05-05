#!/bin/bash

echo "START debug.bat"
#st-util -p 61234 &
~/git_repos/stlink/build/Release/bin/st-util -p 61234 &

gdb-multiarch bin/output.elf
echo "DONE"
