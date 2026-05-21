#!/bin/bash
sessions=( bitcoin lightning lightning2 lightning3)


osascript <<EOF
    tell application "iTerm2"
      tell current window
        create tab with default profile
        tell current session
       	   set execute to "autossh -M 0 operator@nixostestsbckitchen -t 'cd ~/containers-tests-to-delete/workshop-10 && ./term-open.sh'"
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
          set execute to "autossh -M 0 operator@nixostestsbckitchen -t 'cd ~/containers-tests-to-delete/workshop-10 && ./term-open.sh ${i}'"
          write text execute
        end tell
      end tell
    end tell
EOF
done

