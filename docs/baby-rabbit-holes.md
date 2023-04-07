# Baby rabbit holes

Ordered list of "basic" skills that need to be acquired to enjoy the ride.

Go through this slowly. It is tempting to speed-read through a book, call it done, and move on to the next book. To get the most out of this, take your time understanding each section. 

For every 5 minutes you spend reading you should spend 15 minutes tinkering around with what you just read. Break things. 

The sections "Commonly used" are examples you can easily copy/past.

A good *general* cheat sheet page:  [https://github.com/ruanbekker/cheatsheets#readme](https://github.com/ruanbekker/cheatsheets#readme)


## GitHub / Git

- Fork MY₿ONK-core and clone your forked repository it on your laptop (instructions [here](https://docs.github.com/en/get-started/quickstart/fork-a-repo)).
- Commands reference [here](https://git-scm.com/docs/git).
- [Switch to another branch in terminal](https://stackoverflow.com/questions/47630950/how-can-i-switch-to-another-branch-in-git).
- [Switch GitHub account in terminal](https://dev.to/0xbf/switch-github-account-in-terminal-92g).
- Commonly used:

  ```
  git clone https://github.com/mybonk/mybonk-core.git
  git status
  git switch 
  git add .

  git add -a
  git add -A
  git commit -m "commit message"

  git mv filename dir/filename
  git add --all
  git push
  git push -u origin main
  git pull

  ```
## Command line stuff

A *shell* is a user interface for access to an operating system's services. 

A *terminal* is a program that opens a graphical window and lets you interact with the shell.

A *CLI* (command-line interface) is what deal with when you interact with the shell. 


- Terminal vs. iTerm2 ([features](https://iterm2.com/features.html)).
- Shell: 
  - The most important command on the command line is ```man``` (it stands for "manual", so [RTFM](https://en.wiktionary.org/wiki/RTFM)!).
  - ```bash``` and its history (sh, csh, tsh, ksh ...).
  - ```zsh``` adds great new features over ```bash```. (Note that as of macOS Catalina, the default shell in macOS is Zsh and Bash is deprecated), most noticeably:
    - Automatic cd: Just type the name of the directory without ``cd``.
    - Recursive path expansion: e.x. “/u/lo/b” expands to “/usr/local/bin”.
    - Spelling correction and approximate completion: Minor typo mistakes in file or directory names are fixed automatically.
    - Plugin and theme support: This is the greatest feature of Zsh. Use [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh#readme) manage these effortlessly (list of plugins [HERE](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins)).

- Environment variables in Linux-based systems:
  
    - Read ["how Environment Variables Work" (www.howtogeek.com/668503/how-to-set-environment-variables-in-bash-on-linux)](https://www.howtogeek.com/668503/how-to-set-environment-variables-in-bash-on-linux/)
    - ```$SHELL``` The default shell being used on the system.
    - ```$PATH``` Instructs the shell which directories to search for executables, it allows to run commands without having to specify its full path.
    - .etc... .
- Shell commands you must know *really well*:
  - ```ls```, ```cd```, ```type```, ```mkdir```, ```mv```, ```rm```, ```ln```, ```which```,  …
  - ```hostname```, ```whoami```, ```passwd```, ```chmod```, ```chgrp```, …
  - ```ip a```
  - ```history``` 
    - ```echo "$HISTFILE"```
    - ```history | grep [string]```: Find any record in history.
    - ```history -c```: Remove all records.
    - ```history -d 1234```: Remove record number 1234.
      - IMPORTANT: [In Zsh this command does not work](https://apple.stackexchange.com/questions/430640/history-d-does-not-remove-history-entry-but-shows-time-of-history-entry), it is an alias to ``fc`` which doesn't have an option to delete records from the history. <[workaround](https://stackoverflow.com/questions/7243983/how-to-remove-an-entry-from-the-history-in-zsh/63494771#63494771)>
    




    - Don't forget to explore 'i-search' and 'reverse-i-search' using ``Ctrl`` + ``s`` and ``Ctrl`` + ``r`` respectively; Read this [if 'i-search' using ``Ctrl`` + ``s`` does not work](https://stackoverflow.com/questions/791765/unable-to-forward-search-bash-history-similarly-as-with-ctrl-r).
  - ```alias```
  - ```grep```: Find all files containing specific text
    - search all the files in a given directory:
    ```
        grep -rnw '/path/to/somewhere/' -e 'pattern'
    ```
    - only search through those files with ```.c``` or ```.h``` extensions:
    ```
        grep --include=\*.{c,h} -rnw '/path/to/somewhere/' -e "pattern"
    ```
    - exclude searching all the files with ```.o``` extension:
    ```
        grep --exclude=\*.o -rnw '/path/to/somewhere/' -e "pattern"
    ```
    - for directories it's possible to exclude one or more directories using the ```--exclude-dir``` parameter. For example, this will exclude the dirs ```dir1/ ```, ```dir2/``` and all of them matching ```*.dst```:
    ```
        grep --exclude-dir={dir1,dir2,*.dst} -rnw '/path/to/search/' -e "pattern"
    ```
    - ```sudo```
    - ```tee```: a command in command-line interpreters using standard streams which reads standard input and writes it to both standard output and one or more files, effectively duplicating its input. It is primarily used in conjunction with pipes and filters. The command is named after the T-splitter used in plumbing.
   - ```file```

## Text processing
- vi (cheat-sheet [HERE](https://www.thegeekdiary.com/basic-vi-commands-cheat-sheet/))
  - ```$ vi +132 myfile```: Open myfile on line 132
- sed ([https://www.gnu.org/software/sed/manual/sed.html](https://www.gnu.org/software/sed/manual/sed.html)): "stream editor" for editing streams of text too large to edit as a single file, or that might be generated on the fly as part of a larger data processing step: Substitution, replacing one block of text with another.
- awk ([https://github.com/onetrueawk/awk/blob/master/README.md](https://github.com/onetrueawk/awk/blob/master/README.md)): Programming language. Unlike many conventional languages, awk is "data driven": you specify what kind of data you are interested in and the operations to be performed when that data is found.
- - [jq](https://stedolan.github.io/jq/): Lightweight and flexible command-line JSON parser/processor. [reference](https://stedolan.github.io/jq/tutorial/)


## File system
- ```df```: Display disk usage (also checkout the ```glance```Glance
 utility).
  - ```df -hT```. ```-h``` for “human readable” ```-T```, to displays the type of the filesystem.
  - ```df -hT -t ext4```. ```-t ext4``` to display only filesystems of type ext4.
  - ```df -hT -x squashfs -x overlay -x tmpfs -x devtmpfs``` to hide given filesystem types from the output.
- ```du```: Estimate file space usage.
## curl

## gpg, sha-256 …
## ssh
- [Difference between ssh and ~~Telnet~~](https://www.geeksforgeeks.org/difference-ssh-telnet/)
- [ssh](https://goteleport.com/blog/how-to-set-up-ssh-keys/): 
  - OpenSSH
  - How to manage ssh keys
  - .ssh client configuration (```$HOME/.ssh/config```)
  - ssh-keygen
  - passphrase
  - ssh-copy-id: Copy your public key on the server machine in ```$HOME/.ssh/authorized_keys``` 
  - ssh-add
  
  Also read about and setup ssh-agent, it will save you a LOT of time (key management, auto re-connect e.g. when your laptop goes to sleep or reboots ...).
- findssh: ([on GitHub](https://github.com/scivision/findssh#readme)) Platform-independently find SSH servers (or other services with open ports) on an IPv4 subnet in pure Python WITHOUT NMAP. Scan entire IPv4 subnet in less than 1 second.  

## tmux
- (... or alternatives like GNU Screen, Terminator, Byobu, etc.)
- tmux for beginners part 1: https://dev.to/iggredible/tmux-tutorial-for-beginners-5c52 
- tmux for beginners part 2: https://dev.to/iggredible/useful-tmux-configuration-examples-k3g
- cheat sheet
Tmux shortcuts 
  - ````new -s MY_SESSION````
  - ````tmux list-keys````
  - ````tmux list-panes````
  -  ````tmux source-file ~/.tmux.conf````
  - Detach a session: ````Prefix + d```` or ````tmux detach````
  - List sessions: ````tmux ls````
  - Attach to a session: ````tmux attach -t MY_SESSION````
  - List sessions and switch to a different session: ````Prefix + s````
  - Kill a session: ````tmux kill-session -t MY_SESSION````
  - Create a window: ````tmux new-window -n MY_WINDOW```` or ````Prefix + c````
  - Switch to a different window: ````Prefix + n```` (next), ````Prefix + p```` (previous) and ````Prefix + N```` (where ````N```` is the window index number, zero-based)
  - Kill a window: ````tmux kill-window -t MY_WINDOW````
  - Close a pane / window: ````Ctrl + d```` or ````Prefix + x````
## Tor
- .onion 
- tor hidden services
- Tor browsers (https://www.torproject.org/download/)
- torify / torsocks
## processes
- ```systemd```, ```man systemd.service```, ```man systemd.directives```, .etc...
- top
- [systemctl](https://www.howtogeek.com/839285/how-to-list-linux-services-with-systemctl/#:~:text=To%20see%20all%20running%20services,exited%2C%20failed%2C%20or%20inactive.)
  - ```systemctl status bitcoind```
  - ```systemctl start bitcoind```
  - ```systemctl restart bitcoind```
  - ```systemctl stop bitcoind```
  
  - Show all the running processes: ```systemctl --type=service --state=running``` (where ```--state``` can be any of ```running```, ```dead```, ```exited```, ```failed``` or ```inactive```)
  - Show the service definition: ```systemctl cat bitcoind```  
  - Show the service parameters: ```systemctl show bitcoind```


- [journalctl](https://www.digitalocean.com/community/tutorials/how-to-use-journalctl-to-view-and-manipulate-systemd-logs)
  - All the journal entries since the most recent reboot: ```journalctl -b``` 
  - Display the timestamps in UTC: ```journalctl --utc``` 
  - List previous boots: ```journalctl --list-boots```
  - ```journalctl --since "2015-01-10" --until "2015-01-11 03:00"```
  - ```journalctl --since yesterday```
  - ```journalctl --since 09:00 --until "1 hour ago"```
  - ```journalctl -p err -b``` where option '-p' can be any of:
    - ```0: emerg```
    - ```1: alert```
    - ```2: crit```
    - ```3: err```
    - ```4: warning```
    - ```5: notice```
    - ```6: info```
    - ```7: debug```
  - ```journalctl --no-full```
  - ```journalctl --no-pager```
  - ```journalctl -b -u bitcoind -o json```
  - ```journalctl -b -u bitcoind -o json```

  - ```journalctl -u bitcoind.service```
  - ```journalctl -u bitcoind.service -u clightning.service --since today```
  
- [logger](https://www.serverwatch.com/guides/use-logger-to-write-messages-to-log-files/)


## certificate 
- authority
- expiration
- update
## http vs. https
## OS-layer firewall
## partitions filesystem
- /
- /mnt
- /var
- /etc
- /tmp
- /lib


## UEFI vs. Legacy Boot

## Other tools / resources
- [QEMU](https://www.qemu.org/): A generic and open source machine emulator (full-system and user-mode emulation) and virtualizer. It is the emulator the NixOS community uses primarily.
- [WSL](https://devblogs.microsoft.com/commandline/announcing-wsl-2/): Windows Subsystem for Linux to run ELF64 Linux binaries on Windows (if you have Windows system but would like to run Linux programs and commands this is what you need if you prefer not to use a full fledged virtual machine).
- [websocketd](https://github.com/joewalnes/websocketd): Small command-line tool that will wrap an existing command-line interface program, and allow it to be accessed via a WebSocket. WebSocket-capable applications can now be built very easily. As long as you can write an executable program that reads STDIN and writes to STDOUT, you can build a WebSocket server. No networking libraries necessary.
- [wscat](https://github.com/websockets/wscat/blob/master/README.md): WebSocket cat.
- Benchmaring
  - [powertop](https://github.com/fenrus75/powertop/blob/master/README.md): Tool to access various powersaving modes in userspace, kernel and hardware. Monitors processes and shows which utilizes the most CPU allowing to identify those with particular high power demands.
  - [stress-ng](https://wiki.ubuntu.com/Kernel/Reference/stress-ng): Stress test a computer system in various selectable way.
  - [geekbench](https://www.geekbench.com/): Simple tool to quickly benchmark a system's performance ([How to run on Linux](http://support.primatelabs.com/kb/geekbench/installing-geekbench-5-on-linux)) 
  - [iperf3](https://github.com/esnet/iperf): Simple tool to quickly benchmark the maximum achievable bandwidth on IP networks.
- [glances](https://github.com/nicolargo/glances/blob/develop/README.rst) utility: System cross-platform monitoring tool. It allows real-time monitoring of various aspects of your system such as CPU, memory, disk, network usage etc. as well as running processes, logged in users, temperatures, voltages etc.
- [tmuxinator](https://github.com/tmuxinator/tmuxinator/blob/master/README.md): Tool that allows you to easily manage tmux sessions by using yaml files to describe the layout of a tmux session, and open up that session with a single command.


  ![](img/various/tmuxinator_screeshot.gif)

  - ```tmuxinator new [project]```: Create a new project file with given name and open it in your editor.
  - ```tmuxinator list```: List all tmuxinator projects.
  - ```tmuxinator copy [project] [copy_of_project]```: Copy an existing project to a new project and open it in your editor.
  - ```tmuxinator delete [project_a] [project_b] ...```: Deletes given project(s).
  - ```tmuxinator start console -n "console_jay" extra_param="any_string"```: Start a session ```console```, assign it project name "```console_jay```" and extra arbitrary parameter "```extra_param```" to pass value "```any_string```".
  - ```tmuxinator stop [project]```: Stop a tmux session using a project's tmuxinator config.
  - ```tmux list-sessions``` / ```tmux ls```
  - ```tmux kill-session -t name_of_session_to_kill```
  - ```tmux kill-session -a``` : Kills all the sessions apart from the active one.
  - ```tmux kill-session``` : Kills all the sessions.
  - ```tmux kill-server``` : Kills the tmux server.
  
- VPN
  - [Wireguard](https://www.wireguard.com/quickstart/) This VPN technology is built into the kernel; Client app widely available, allows to connect to your local network remotely using a simple QR code to authenticate.
  - [Zerotier](https://www.zerotier.com/) Another VPN alternative.
  
- Chaumian ecash system
  - [Cashu](https://cashu.space/): Cashu is a free and open-source Chaumian ecash system built for Bitcoin. Cashu offers near-perfect privacy for users of custodial Bitcoin applications. Nobody needs to knows who you are, how much funds you have, and whom you transact with.

## NixOS commands reminder
- Nice Nix cheat sheet: [https://github.com/brainrake/nixos-tutorial/blob/master/cheatsheet.md](https://github.com/brainrake/nixos-tutorial/blob/master/cheatsheet.md)
- NixOS the "traditional" vs. the "Flakes" way: 

  Flakes have been introduced with Nix 2.4; although still an "**experimental**" feature it is the way forward, we advise you to learn and to use Flakes already.
- ```nix version```: Get running nix version (important as the MY₿ONK console might be running a different version from the one on MY₿ONK orchestrator).
- ```nix-shell```: Start an interactive shell based on a Nix expression. This is distinct from ```nix shell```.
- ```nix-build```: Build a Nix expression. This is distinct from ```nix build```.
- ```nix-channel```
- ```nix-collect-garbage```
- ```nix-copy-closure```
- ```nix-deamon```
- ```nix-env```
- ```nix-hash```
- ```nix-instantiate``` 
- ```nix-prefetch-url```
- ```nix-store```

- ```nix repl``` ([nix repl](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-repl.html)): Start an interactive environment for evaluating Nix expressions.

- Garbage collection:
  - Ref. the options ```keep-derivations``` (default: ```true```) and ```keep-outputs``` (default: ```false```) in the Nix configuration file.
  - ```nix-collect-garbage -delete-old```: Quick and easy way to clean up your system, deletes **all** old generations of **all** profiles in ```/nix/var/nix/profiles```. See the other options below for a more "surgical" way to garbage collect.
  - ```nix-env --delete-generations old```: Delete all old (non-current) generations of your current profile.
  - ```nix-env --delete-generations 10 11 23```: Delete a specific list of generations
  - ```nix-env --delete-generations 14d```: Delete all generations older than 14 days.
  - ```nix-store --gc --print-dead```: Display what files would be deleted.
  - ```nix-store --gc --print-live```: Display what files would not be deleted. 
  - After removing appropriate old generations (after having used ```nix-env``` with an argument ```--delete-generations```) - you can run the garbage collector as follows: ```nix-store --gc```
## Podcasts
- nixbitcoin-dev with Stefan Livera: A security focused bitcoin node https://stephanlivera.com/episode/195/

## Books
- [Introduction to the Mac command line](https://github.com/ChristopherA/intro-mac-command-line) (on GitHub)
- [Learn Bitcoin from the command line](https://github.com/BlockchainCommons/Learning-Bitcoin-from-the-Command-Line#readme) (on GitHub)
- [Mastering the Lightning Network](https://github.com/lnbook/lnbook#readme) (on GitHub)
## 
- **John Perry Barlow: The Declaration of Independence of Cyberspace**
  - Document: [https://cryptoanarchy.wiki/people/john-perry-barlow](https://cryptoanarchy.wiki/people/john-perry-barlow)
  - Audio, red by the author: [https://www.youtube.com/watch?v=3WS9DhSIWR0](https://www.youtube.com/watch?v=3WS9DhSIWR0)
- **Michael W. Dean: Users Manual for The Human Experience** 
  - pdf book: [https://michaelwdean.com/UMFTHE/Users_Manual_for_The_Human_Experience-eBook.pdf](https://michaelwdean.com/UMFTHE/Users_Manual_for_The_Human_Experience-eBook.pdf)
  - audiobook on YouTube: https://www.youtube.com/watch?v=xpJMFBpGR2s
  
