#target remote *:4242
set confirm off
target remote *:61234
load
break main
tui enable

