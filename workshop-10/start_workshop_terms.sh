#!/bin/bash
sessions=( lightning bitcoin )


osascript <<EOF
    tell application "iTerm2"
      tell current window
        create tab with default profile
        tell current session
       	   set execute to "ssh operator@nixostestsbckitchen -t 'cd ~/containers-tests-to-delete/workshop-10 && ./term-open.sh'"
           write text execute
        end tell
      end tell
    end tell
EOF

for i in "${sessions[@]}"
do
  osascript <<EOF
    #tell application "iTerm2" to activate
    tell application "iTerm2"
      tell current window
        create tab with default profile
        tell current session
          set execute to "ssh operator@nixostestsbckitchen -t 'cd ~/containers-tests-to-delete/workshop-10 && ./term-open.sh ${i}'"
          write text execute
        end tell
      end tell
    end tell
EOF
done

