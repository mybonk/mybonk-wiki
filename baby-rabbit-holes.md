# Baby rabbit holes

Ordered list of "basic" skills that need to be acquired to enjoy the ride.

Go through this slowly. It is tempting to speed-read through a book, call it done, and move on to the next book. To get the most out of this, take your time understanding each section. 

For every 5 minutes you spend reading you should spend 15 minutes tinkering around with what you just read. Break things. 

The sections "Commonly used" are examples you can easily copy/past.

A good *general* cheat sheet page:  [https://github.com/ruanbekker/cheatsheets#readme](https://github.com/ruanbekker/cheatsheets#readme)


## Git / GitHub

- Fork MY₿ONK-core and clone your forked repository it on your laptop (instructions [here](https://docs.github.com/en/get-started/quickstart/fork-a-repo)).
- What is a "*pull request*"? (video explanation): https://www.youtube.com/watch?v=For9VtrQx58 
- Difference between *merge* is "*rebase*"? (video explanation): https://www.youtube.com/watch?v=dO9BtPDIHJ8
- Commands reference [here](https://git-scm.com/docs/git).
- [How to Setup Passwordless Authentication for git push in GitHub](https://www.cyberithub.com/how-to-setup-passwordless-authentication-for-git-push-in-github/)
- [Switch to another branch in terminal](https://stackoverflow.com/questions/47630950/how-can-i-switch-to-another-branch-in-git).
- [Switch GitHub account in terminal](https://dev.to/0xbf/switch-github-account-in-terminal-92g).
- Commonly used:
  - Your identity
    - The first thing you should do when you install Git is to set your user name and email address. This is important because every Git commit uses this information, and it’s immutably baked into the commits you start creating:
      ```
      $ git config --global user.name "John Doe"
      $ git config --global user.email johndoe@example.com
      ```
  
  ```
  more ~/.gitconfig
  git config -l
  git config user.name

  git clone https://github.com/mybonk/mybonk-core.git
  git remote show origin
  git status
  git show
  git log master --graph
  git branch
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

  git remote set-url origin https://git-repo/new-repository.git 
  git remote set-url <remote_name> <ssh_remote_url>
  git remote -v

  git diff dir/filename 

  git log -S "signet" --pretty=format:'%h %an %ad %s'
  
  git blame README.md
  git blame -e README.md
  git blame -L 1,5 README.md
  git blame -w README.md
  git blame -M README.md
  git blame -C README.md

  ```
- [GitHub CLI](https://docs.github.com/en/github-cli/github-cli/about-github-cli): Command-line tool that brings pull requests, issues, GitHub Actions, and other GitHub features to your terminal, so you can do all your work in one place.
    - Authenticate with your GitHub account: ```gh auth login```
    - ...
- [Source Tree](https://www.sourcetreeapp.com/) application: Free graphical user interface (GUI) desktop client that simplifies how you interact with Git repositories (some people are more comfortable with this rather than using Git CLI). Here is are [good simple tutorials](https://confluence.atlassian.com/get-started-with-sourcetree) to get started.

## Command line stuff

A *shell* is a user interface for access to an operating system's services. 

A *terminal* is a program that opens a graphical window and lets you interact with the shell.

It is common that the keyboard layout the system is configured with is different from the keyboard you actually use (e.g. system keyboard configured US layout but you use a keyboard with a French layout), read this article "https://www.baeldung.com/linux/console-change-keyboard-layout" to fix this.

A *CLI* (command-line interface) is what deal with when you interact with the shell. 

- [RTFM!](https://en.wiktionary.org/wiki/RTFM)
  - The most important command is ```man``` which stands for "manual" e.g.
    ```
    $ man mkdir
    ```
  - Hit ```h``` for help and ```q``` to leave the manual.
  - scroll through the manual using 'arrow up' and 'arrow down'.
  - Jump pages up and down using 'space bar' and 'Shift + space bar'.
  - Search for a term in a manual using ```/``` e.g. ```/ignore``` then hit: 
     - ```n``` for next match 
     - ```Shift + n``` for previous match
  - Search for a term in all the manuals: ``````

- System version
  - OS name and version in Linux: 
    - ```cat /etc/os-release```
  - Linux kernel version:
    - ```hostnamectl```

- Terminal vs. iTerm2 ([features](https://iterm2.com/features.html)).
  - iTerm2 hotkeys: 
    - toggle maximize window: `Cmd` + `Alt` + `=`
    - toggle full screen: `Cmd` + `Enter`.
    - make font larger: `Cmd` + `+`
    - make font smaller: `Cmd` + `-`
- Shell: 
  - ```bash``` and its history (sh, csh, tsh, ksh ...).
  - ```zsh``` adds great new features over ```bash```. (Note that as of macOS Catalina, the default shell in macOS is Zsh and Bash is deprecated), most noticeably:
    - Automatic cd: Just type the name of the directory without ``cd``.
    - Recursive path expansion: e.x. “/u/lo/b” expands to “/usr/local/bin”.
    - Spelling correction and approximate completion: Minor typo mistakes in file or directory names are fixed automatically.
    - Plugin and theme support: This is the greatest feature of Zsh. Use [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh#readme) manage these effortlessly (list of plugins [HERE](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins)).

- Environment variables in Linux-based systems:
  
    - Read ["how Environment Variables Work" (www.howtogeek.com/668503/how-to-set-environment-variables-in-bash-on-linux)](https://www.howtogeek.com/668503/how-to-set-environment-variables-in-bash-on-linux/)
      - ```$ export EDITOR=vi```
      - ```$ echo $EDITOR```
      - ```$ printenv```: Print all the environment variables.
        - ```$SHELL``` The default shell being used on the system.
        - ```$PATH``` Instructs the shell which directories to search for executables, it allows to run commands without having to specify its full path.
        - .etc... .
- Shell commands you must know *really well*:
  - ```pwd```, ```ls```, ```cd```, ```type```, ```mkdir```, ```mv```, ```rm```, ```ln```, ```which```, ```whereis```, ```cat```, ```head```, ```tail```, ```more```, ```tee``` …
  - ```tree```: Outputs a depth-indented listing of files making it easy to visualize the organization of files and directories within a given path. With no arguments the tree lists the files in the current directory. When directory arguments are given, the tree lists all the files or directories found in the given directories each in turn. 
  - ```uname -a```, ```hostname```, ```whoami```, ```passwd```, ```chown```, ```chgrp```, ```chmod```, …
  - ```uptime```:  Tell how long the system has been running.
  - ```ip a``` / ```hostname -I```: Tells you the IP address of your system.
  - ```su```/```sudo```, ```doas```: Used to assume the identity of another user on the system (they are both similar tools, ```doas``` has been ported from the OpenBSD project and could be assumed "safer" than ```sudo``` as it is less error-prone e.g. when setting up somewhat complicated patterns in ```/etc/sudoers```).
  - ```history``` 
    - ```echo "$HISTFILE"```
    - ```history | grep [string]```: Find any record in history.
    - ```history -c```: Remove all records.
    - ```history -d 1234```: Remove record number 1234.
      - IMPORTANT: [In Zsh this command does not work](https://apple.stackexchange.com/questions/430640/history-d-does-not-remove-history-entry-but-shows-time-of-history-entry), it is an alias to ``fc`` which doesn't have an option to delete records from the history. <[workaround](https://stackoverflow.com/questions/7243983/how-to-remove-an-entry-from-the-history-in-zsh/63494771#63494771)>
    
    - Don't forget to explore 'i-search' and 'reverse-i-search' using ``Ctrl`` + ``s`` and ``Ctrl`` + ``r`` respectively; Read this [if 'i-search' using ``Ctrl`` + ``s`` does not work](https://stackoverflow.com/questions/791765/unable-to-forward-search-bash-history-similarly-as-with-ctrl-r).
  - ```alias```
  - ```grep```: Find all files containing specific text
    - On a file:
      - Most basic use
        ```
        $ grep 'keyword' /path/to/file.log
        ```
      - To also show the 5 lines before and the 2 lines after the keyword occurrences as well as highlighting the occurrences in color:
        ```$ grep -B 5 -A 2 --color 'keyword' /path/to/file.log```
    - On directories:
      - Search all the files in a given *directory*:
        ```
        grep -rnw '/path/to/somewhere/' -e 'pattern'
        ```
      - Only search through those files with ```.c``` or ```.h``` extensions:
        ```
        grep --include=\*.{c,h} -rnw '/path/to/somewhere/' -e "pattern"
        ```
      - Exclude searching all the files with ```.o``` extension:
        ```
        grep --exclude=\*.o -rnw '/path/to/somewhere/' -e "pattern"
        ```
      - Exclude one or more directories using the ```--exclude-dir``` parameter. For example, this will exclude the dirs ```dir1/ ```, ```dir2/``` and all of them matching ```*.dst```:
        ```
        grep --exclude-dir={dir1,dir2,*.dst} -rnw '/path/to/search/' -e "pattern"
        ```
    - ```tee```: a command in command-line interpreters using standard streams which reads standard input and writes it to both standard output and one or more files, effectively duplicating its input. It is primarily used in conjunction with pipes and filters. The command is named after the T-splitter used in plumbing.
   - ```watch```: Execute a program periodically showing output in fullscreen e.g. 
    - ```$ watch 'du -ac -d0 /data/bitcoind/blocks'```
    - ```$ watch -n 2 'bitcoin-cli -getinfo | grep progress'```
   - ```md5sum```: Calculates and verifies 128-bit MD5 hashes as a compact digital fingerprint of a file. There is theoretically an unlimited number of files that will have any given MD5 hash.
  - Command to search for files through directories.
    - ```find /search/directory/ -name "matching file search criteria" -actions```
    - ```find /dir/to/search -name "pattern" -print```
    - ```find /dir/to/search -name "file-to-search" -print```
    - ```find /dir/to/search -name "file-to-search" -print [-action]```

## Text processing

- ```vi``` (cheat-sheet [HERE](https://www.thegeekdiary.com/basic-vi-commands-cheat-sheet/))
  - ```$ vi +132 myfile```: Open myfile on line 132
- ```sed``` ([https://www.gnu.org/software/sed/manual/sed.html](https://www.gnu.org/software/sed/manual/sed.html)): "stream editor" for editing streams of text too large to edit as a single file, or that might be generated on the fly as part of a larger data processing step: Substitution, replacing one block of text with another.
- ```awk``` ([https://github.com/onetrueawk/awk/blob/master/README.md](https://github.com/onetrueawk/awk/blob/master/README.md)): Programming language. Unlike many conventional languages, awk is "data driven": you specify what kind of data you are interested in and the operations to be performed when that data is found.
- [jq](https://stedolan.github.io/jq/): Lightweight and flexible command-line JSON parser/processor. [reference](https://stedolan.github.io/jq/tutorial/)
- [rg](https://www.linode.com/docs/guides/ripgrep-linux-installation/#install-ripgrep-on-ubuntu-and-debian) (also known as ```ripgrep```): Recursively search the current directory for lines matching a pattern, very useful to find whatever document containing whatever text in whatever [sub]directory.
  - ```$ rg what_i_am_looking_for MyDoc_a.php MyDoc_b.php```   Look for string 'what_i_am_looking_for' in MyDoc_a.php and MyDoc_b.php
  - ```$ rg what_i_am_looking_for  MyDoc.php -C 2```: Return results with *context*, displaying 2 lines before and 2 lines after the match in the output. Also try the options ```-B``` and ```-A``` (number of lines *before* and *after* the match).
  - ```$ rg 'Error|Exception' MyDoc.php```: Searches the file for either ```Error``` or ```Exception```.
  - ```$ rg 't.p' MyDoc.php```: Looks for a ```t``` and a ```p``` with any single character in between.
  - ```$ rg ssl -i```: ***Recursively*** searches for instances of ssl in a case-insensitive manner.
  - ```$ rg service /etc/var/configuration.nix -i```: ***Recursively*** searches a specific directory for instances of *service* in a case-insensitive manner.
  - ```rg -g 'comp*'  key``` Searches only for the pattern ```key``` in files beginning with the substring ```comp```.
  - ```-l``` option to only list the files having a match without additional details/
  - ```-i``` option for case-insensitive search.
  - ```-S``` option for smart case search.
  - ```-F``` option to treat the search string as a string literal ([regex](https://docs.rs/regex/1.5.4/regex/#syntax) syntax).
  - ```$ rg --type-list``` List of the available file types.
  - ```$ rg key -t json``` Restricts the search for the pattern key to json files only.

## File processing

  - ```$ tar -xvf myfile.tar.gz```: Untar a file.

## File system / Block devices
- ```lsblk```: List information about the system's available or the specified block devices.

- ```df```: Display disk usage:
  - ```df -hT```. ```-h``` for “human readable”, ```-T``` to displays the type of the filesystem.
  - ```df -hT .```. '```.```' for whatever partition the current directory is residing on.
  - ```df -hT -t ext4```. ```-t ext4``` to display only filesystems of type ext4.
  - ```df -hT -x squashfs -x overlay -x tmpfs -x devtmpfs``` to hide given filesystem types from the output.
- ```du```: Estimate file space usage. 
  - ```$ du -h /data```. ```-h``` for “human readable”.
  - ```$ du -s /data```. ```-s``` for “summary”.
  - ```$ du -ah --time```. Shows the time of the last modification to any file in the directory or subdirectory. ``--time`` with with the ``-ah`` flags is very useful e.g. someone writes files somewhere by accident and you need to find where.

- ```fdisk```: Dialog-driven program to see and manipulate disk partition table.
  - ```fdisk -l```: List the system's partition scheme.
  - ```fdisk -l | grep "Disk /"```: See all the available disks.
  - ```fdisk /dev/sdc```: Enter the interactive mode to manipulate the partition table of the disk ```/dev/sdc``` 
- ```mkfs.ext4 /dev/sdc1```: Formats the partition ```/dev/sdc1``` in ext4 file system format.

- Interesting threads about ZFS:
  - ["what is the point of ZFS with only 1 disk"](https://www.truenas.com/community/threads/single-drive-zfs.35515/).
  - ["benefit/risk of ZFS with only 1 disk"](https://unix.stackexchange.com/questions/672151/create-zfs-partition-on-existing-drive) (also includes the commands for a little ZFS experimentation).
## curl
- ```curl -O https://testdomain.com/testfile.tar.gz```: Save file.
- ```curl -o mydownload.tar.gz https://testdomain.com/testfile.tar.gz``` (**little 'o'**): Save file as ```mydownload.tar.gz```.
- ```curl -I https://www.google.com```: Query the header of a server (same as ```-head```). 
- ```curl -k https://localhost/my_test_endpoint```: Ignore invalid or self-signed certificates (same as ```--insecure```).
- Make a POST request (through parameters and JSON):
  - ```curl --data "param1=test1&param2=test2" http://test.com```
  - ```curl  -H 'Content-Type: application/json' --data '{"param1":"test1","param2":"test2"}' http://www.test.com```
- ```curl -X 'PUT' -d '{"param1":"test1" "param2":"test3"}' \http://test.com/1```: Specify a type of request (here 'PUT').
- ```curl -u <user:password> https://my-test-api.com/endpoint1```: Basic Authentication for various protocols (same as ```-user```).
- Update name resolution: test an API before deploying and want to hit in the endpoint in the test machine rather than the actual endpoint, you can pass in a custom resolution for that request: Works similarly to ```/etc/hosts``` host-resolution.
- Upload a file: curl with the -F option emulates a filled-in form when the user has clicked the submit button. This option causes curl to POST data using the Content-Type multipart/form-data: 
  - ```curl -F @field_name=@path/to/local_file <upload_URL>```
  - ```curl -F @field_name=@path/to/local_file_1, @field_name=@path/to/local_file_2, @field_name=@path/to/local_file_3,  <upload_URL>```
- ```curl -w "%{time_total}\n" -o /dev/null -s www.test.com```: Use ```-w``` to display information (stdout) after a transfer. ```total_time``` is one of the interesting parameters curl returns

## wget
- Download a complete remote directory, includes no parent and recursive to only get the desired directory.```wget --no-parent -r http://WEBSITE.com/DIRECTORY```

## Cryptography
- The difference between seed words and private key: https://youtu.be/Y_A3j8GzaO8

## ssh & rsync
- [Difference between ssh and ~~Telnet~~](https://www.geeksforgeeks.org/difference-ssh-telnet/)
- ssh: 
  - OpenSSH
  - How to setup and manage ssh keys: https://goteleport.com/blog/how-to-set-up-ssh-keys/
  - .ssh client configuration (```~/.ssh/config```)
  - ssh-keygen
  - passphrase
  - ssh-copy-id: Copy your public key on the server machine in ```~/.ssh/authorized_keys``` 
  - ssh-add
  
  Also read about and setup ssh-agent, it will save you a LOT of time (key management, auto re-connect e.g. when your laptop goes to sleep or reboots ...).

- [rsync](https://apoorvtyagi.tech/scp-command-in-linux): 
  - rsync uses a delta transfer algorithm and a few optimizations to make the operation a lot faster compared to ssh. The files that have been copied already won't be transferred again (unless they changed since). Can be run ad-hoc on the command line or configured to run as a deamon on the systems to keep files in sync.
  - rsync allows to restart failed transfers - you just reissue the same command and it will pick up where it left off, whereas scp will start again from scratch.
  - rsync needs to be used over SSH to be secure.
  - Example 1: From local to local (instead of using ```scp```):
    ````bash
    # rsync -avhW --progress --exclude --exclude '*/*.lock' /unmountme/bitcoind/{blocks,chainstate,indexes} /data/bitcoind
    ````
  - Example 2: Same thing but also gives a visual indication of the copy progress as well as completion time estimate ('ETA'):
    ````bash
    # rsync -avhW --stats --exclude '*/*.lock' --human-readable /unmountme/bitcoind/{blocks,chainstate,indexes} /data/bitcoind | pv -lep -s $(find /unmountme/bitcoind/{chainstate,blocks,indexes} -type f | wc -l)
    ````
- Network:
  - Speed test: [https://www.speedtest.net]()
  - Scanners:
    - [findssh](https://github.com/scivision/findssh#readme): Command line tool to scan entire IPv4 subnet in less than 1 second. Without NMAP. It is extremely quick but sometimes it misses some hosts so run it a couple of time to be sure it scanned them all.

    Example:
    ```bash
    $ python3 -m findssh -b 192.168.0.1 -s ssh -v
    searching 192.168.0.0/24
    DEBUG:asyncio:Using selector: EpollSelector
    DEBUG:root:[Errno 111] Connect call failed ('192.168.0.19', 22)
    (IPv4Address('192.168.0.82'), 'SSH-2.0-OpenSSH_8.4p1 Debian-5+d')
    (IPv4Address('192.168.0.136'), 'SSH-2.0-OpenSSH_9.1')
    (IPv4Address('192.168.0.106'), 'SSH-2.0-OpenSSH_8.4p1 Debian-5+d')
    DEBUG:root:[Errno 111] Connect call failed ('192.168.0.150', 22)
    (IPv4Address('192.168.0.100'), 'SSH-2.0-OpenSSH_7.4')
    DEBUG:root:[Errno 111] Connect call failed ('192.168.0.44', 22)
    ```
    - [Angry IP Scanner](https://angryip.org/): Scans LAN and WAN, IP Range, Random or file in any format, provides GUI as well as CLI.

## tmux
- (... or alternatives like GNU Screen, Terminator, Byobu, etc.)
- tmux for beginners part 1: https://dev.to/iggredible/tmux-tutorial-for-beginners-5c52 
- tmux for beginners part 2: https://dev.to/iggredible/useful-tmux-configuration-examples-k3g

-  ````tmux source-file ~/.tmux.conf````
Tmux shortcuts 
  - ````new -s MY_SESSION````
  - ````tmux list-keys````
  - Sessions
    - List sessions and switch to a different session: ````Prefix + s```` (or ````tmux ls```` followed by ````tmux attach -t SESSION````).
    - Detach a session: ````Prefix + d```` or ````tmux detach````
    - Kill a session: ````tmux kill-session -t MY_SESSION````
  - Windows:
    - Create a window: ````Prefix + c```` or ````tmux new-window -n MY_WINDOW````
    - Close a pane / window: ````Ctrl + d```` or ````Prefix + x````
    - Switch to a different window: ````Prefix + n```` (next), ````Prefix + p```` (previous) and ````Prefix + N```` (where ````N```` is the window index number, zero-based).
    - Kill a window: ````tmux kill-window -t MY_WINDOW````
  - Panes
    - List all the panes: ````Prefix + q```` (or ````tmux list-panes````).
    - Jump into a specific pane: ````Prefix + q```` followed by the pane number you want to jump into.
    - Move to next pane: ````Prefix + o````
    - Switch to last pane: ````Prefix + ;````
    
## Tor
- .onion 
- tor hidden services
- Tor browsers (https://www.torproject.org/download/)
- torify / torsocks

## I2P
- Tor vs I2P ([https://www.cloudwards.net/i2p-vs-tor/](https://www.cloudwards.net/i2p-vs-tor/))
## processes
- ```ps```, ```pstree```, ```top```
- ```systemd```
  - ```man systemd.unit```
  - ```man systemd.service```
  - ```man systemd.directives```
- [hostnamectl](https://man7.org/linux/man-pages/man1/hostnamectl.1.html): Query and change the system hostname
       and related settings.
  - ```hostnamectl status```
  - ```hostnamectl hostname```: Query hostname.
  - ```hostnamectl hostname <name>```: Change hostname.
- [systemctl](https://www.howtogeek.com/839285/how-to-list-linux-services-with-systemctl/#:~:text=To%20see%20all%20running%20services,exited%2C%20failed%2C%20or%20inactive.)
  
  - ```systemctl status```
  - ```systemctl status bitcoind```
  - ```systemctl start bitcoind```
  - ```systemctl restart bitcoind```
  - ```systemctl stop bitcoind```
  - ```systemctl enable --now bitcoind```
  - ```systemctl disable bitcoind```
  
  - ```systemctl list-unit-files --type service -all```: List all the services on your system and their status.
  - Show all the running processes: ```systemctl --type=service --state=running``` (where ```--state``` can be any of ```running```, ```dead```, ```exited```, ```failed``` or ```inactive```).
  - ```systemctl daemon-reload```: Reload systemd files. If you change a service file in /etc/systemd/system/, daemon-reload will reload these files.
  - ```pstree```: Tool to display a tree of processes.
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

What is the difference between IPtables and UFW Linux firewalls? 

UFW is built upon IPtables, IPtables a very flexible tool but it’s more complex as compared to UFW. Also IPtables requires a deeper understanding of TCP/IP, which might not be the case with every Linux user, so UFW is the solution. UFW allows the user to configure firewall rules easily using IPtables under the hood. Hence, for an average Linux user UFW is the best way to get started with setting up different firewall rules. 

We discuss and use UFW in our scope. 

In the NixOS the following commands are replaced by configuration parameters in the its configuration file.
- ```sudo netstat -lptu```: See what port is open and what process is listening.
- ```sudo ufw allow 9999```: Open port 9999.
- ```sudo ufw enable```: In case ```ufw``` is not running (check with sudo ```ufw``` status).



## partitions filesystem
- ```findmnt```: Lists all mounted filesytems or search for a filesystem. It is able to search in /etc/fstab, /etc/fstab.d, /etc/mtab or /proc/self/mountinfo. If device or mountpoint is not given, all filesystems are shown.
  - `/`
  - `/mnt`
  - `/var`
  - `/etc`
  - `/tmp`
  - `/lib`


## UEFI vs. Legacy Boot

## Other tools / resources
- [QEMU](https://www.qemu.org/): A generic and open source machine emulator (full-system and user-mode emulation) and virtualizer. It is the emulator the NixOS community uses primarily.
- [WSL](https://devblogs.microsoft.com/commandline/announcing-wsl-2/): Windows Subsystem for Linux to run ELF64 Linux binaries on Windows (if you have Windows system but would like to run Linux programs and commands this is what you need if you prefer not to use a full fledged virtual machine).
- [websocketd](https://github.com/joewalnes/websocketd): Small command-line tool that will wrap an existing command-line interface program, and allow it to be accessed via a WebSocket. WebSocket-capable applications can now be built very easily. As long as you can write an executable program that reads STDIN and writes to STDOUT, you can build a WebSocket server. No networking libraries necessary.
- [wscat](https://github.com/websockets/wscat/blob/master/README.md): WebSocket cat.
- Benchmaring
  - [powertop](https://github.com/fenrus75/powertop/blob/master/README.md): Tool to access various powersaving modes in userspace, kernel and hardware. Monitors processes and shows which utilizes the most CPU allowing to identify those with particular high power demands.
  - [stress-ng](https://wiki.ubuntu.com/Kernel/Reference/stress-ng): Stress test a computer system in various selectable way.
  - [Byte UNIX Bench](https://github.com/kdlucas/byte-unixbench/tree/master): Since 1983, provide a basic indicator of the performance of a Unix-like system; hence, multiple tests are used to test various aspects of the system's performance.
  - [geekbench](https://www.geekbench.com/): Simple tool to quickly benchmark a system's performance ([How to run on Linux](http://support.primatelabs.com/kb/geekbench/installing-geekbench-5-on-linux)) 
  - [iperf3](https://github.com/esnet/iperf): Simple tool to quickly benchmark the maximum 
  achievable bandwidth on IP networks.
    - Run iperf3 as a server: ```iperf3 -s```
    - Run an iperf3 server on a specific port: ```iperf3 -s -p port```
    - Start bandwidth test: ```iperf3 -c server```
    - Run iperf3 in multiple parallel streams: ```iperf3 -c server -P streams```
    - Reverse direction of the test. Server sends data to the client: ```iperf3 -c server -R```
  - ```lscpu```: Part of ```util-linux```, command to display information about the CPU architecture.
  - ```lsmem```: Part of ```util-linux```, command to list the ranges of available memory with their online status.
  - ```memtester```: Effective userspace tester for stress-testing the memory subsystem. It is very effective at finding intermittent and non-deterministic faults.
  - ```memusage```: Profile memory usage of a program.
  - ```dmesg```: Shows Kernel Messages.
- [glances](https://github.com/nicolargo/glances/blob/develop/README.rst) utility: System cross-platform monitoring tool. It allows real-time monitoring of various aspects of your system such as CPU, memory, disk, network usage etc. as well as running processes, logged in users, temperatures, voltages etc.
- [htop](https://www.geeksforgeeks.org/htop-command-in-linux-with-examples/amp/): Similar to glances above.
- [btop](https://github.com/aristocratos/btop): Similar tool to ```glances``` and ```htop``` above.
- [tmuxinator](https://github.com/tmuxinator/tmuxinator/blob/master/README.md): Tool that allows you to easily manage tmux sessions by using yaml files to describe the layout of a tmux session, and open up that session with a single command.

  ![](docs/img/various/tmuxinator_screeshot.gif)

  For your convenience, in [MY₿ONK](https://github.com/mybonk/mybonk-wiki) Wiki there is a [tmuxinator template](https://github.com/mybonk/mybonk-core/blob/master/.tmuxinator.yml) you can reuse: 

  ```$ tmuxinator start -p .tmuxinator_console.yml console node="console_jay"```

    - Adjust the parameter -p accordingly if you are not running the command from the repo's root.
    - You must pass the extra custom parameter node that must be either an IP address or a hostname (or in .ssh/config).


  - ```tmuxinator new [project]```: Create a new project file with given name and open it in your editor.
  - ```tmuxinator list```: List all tmuxinator projects.
  - ```tmuxinator copy [project] [copy_of_project]```: Copy an existing project to a new project and open it in your editor.
  - ```tmuxinator delete [project_a] [project_b] ...```: Deletes given project(s).
  - ```tmuxinator start -p your_tmuxinator_config.yml```: Start tmuxinator using custom configuration file (as opposed to it picking it up from default location like ```˜/.config/tmuxinator\```).
  - ```tmuxinator start console -n "console_jay" extra_param="any_string"```: Start a session ```console```, assign it project name "```console_jay```" and extra arbitrary parameter "```extra_param```" to pass value "```any_string```".
  - ```tmuxinator stop [project]```: Stop a tmux session using a project's tmuxinator config.
  - ```tmux list-sessions``` / ```tmux ls```
  - ```tmux kill-session -t name_of_session_to_kill```
  - ```tmux kill-session -a``` : Kills all the sessions apart from the active one.
  - ```tmux kill-session``` : Kills all the sessions.
  - ```tmux kill-server``` : Kills the tmux server.
  - ```tmux-resurrect``` and ```tmux-continuum```: Tmux plugins to persist sessions across restarts.

- VPN / tunnels
  - [Wireguard](https://www.wireguard.com/quickstart/) This VPN technology is built into the kernel; Client apps widely available (e.x. Tailscale), allows to connect to your local network remotely using a simple QR code to authenticate.
  - [Tailscale](https://github.com/tailscale): [Quick tutorial](https://www.infoworld.com/article/3690616/tailscale-fast-and-easy-vpns-for-developers.html) Rapidly deploy a WireGuard-based VPN, a "Zero-config VPN": Automatically assigns each machine on your network a unique 100.x.y.z IP address, so that you can establish stable connections between them no matter where they are in the world, even when they switch networks, and even behind a firewall. Tailscal enodes uses DERP (Designated Encrypted Relay for Packets) to proxy *encrypted* WireGuard packets () through the Tailscale cloud servers when a direct path cannot be found or opened. It uses curve25519 keys as addresses.

    - Commonly used:  
    ```
    # tailscaled
    $ tailscale help
    $ tailscale login
    $ tailscale up
    $ tailscale down
    $ tailscale status
    $ tailscale netcheck
    $ tailscale ssh console_jay
    
    ```
  - [Zerotier](https://www.zerotier.com/): Another VPN alternative.
  - [ngrok](https://ngrok.com/docs/getting-started/): Exposes local networked services behinds NATs and firewalls to the public internet over a secure tunnel. Share local websites, build/test webhook consumers and self-host personal services.
    - [Sign up (or login)](https://dashboard.ngrok.com/) to get a TOKEN then run: 
    ```$ ngrok config add-authtoken TOKEN```
     - ```$ ngrok http 8000```
  
- Chaumian ecash system
  - [Cashu](https://cashu.space/): Cashu is a free and open-source Chaumian ecash system built for Bitcoin. Cashu offers near-perfect privacy for users of custodial Bitcoin applications. Nobody needs to knows who you are, how much funds you have, and whom you transact with.

- [XSATS.net](https://xsats.net/): bitcoin/sats to and from world currencies, spot price or for any given date.
- [md5calc](https://md5calc.com/hash/sha256): Website to calculate the Hash of any string. 

## Common Nix commands
- Nice Nix cheat sheet: 
  - [https://github.com/brainrake/nixos-tutorial/blob/master/cheatsheet.md](https://github.com/brainrake/nixos-tutorial/blob/master/cheatsheet.md)
- Search the Nix ecosystem:
  - [https://search.nixos.org/](): Search Nix packages, NixOS options, Flakes.
  - [https://noogle.dev](): Search nix functions based on type, name, description, example, category .etc..
- NixOS the "traditional" vs. the "Flakes" way: 
  - Flakes have been introduced with Nix 2.4
  - Although still flagged as "*experimental*" feature it is the way forward, we advise you to learn Flakes already.
- Run nix software with no installation steps:
  - Not using flakes: 
    - Load ```memtester``` from nixpkgs and make it available from interactive shell:  ```nix-shell -p memtester```.
  - Using flakes: 
    - [https://determinate.systems/posts/nix-run]()
  
- ```nix --version```: Get running nix version.
- ```nix-shell```: Start an interactive shell based on a Nix expression. This is distinct from ```nix shell```.
- ```nix-build```: Build a Nix expression. This is distinct from ```nix build```.
- ```nix-channel```
- ```nix-collect-garbage```
- ```nix-copy-closure```
- ```nix-deamon```
- ```nix-env```
- ```nix-hash```
- ```nix-instantiate``` (same as ```nix-instantiate default.nix```)
  - ```nix-instantiate --eval```: Very easy way to evaluate a nix file.
  - ```nix-instantiate --eval --strict```: ```--strict``` tries to evaluation the entire result (otherwise may return ```<CODE>``` blocks).
  - ```nix-instantiate --eval --json --strict```: Always use ```--strict``` with ```--json``` (otherwise ```<CODE>``` blocks may result in json not being able to parse).
  - Similarly with Flakes enabled you could use ```nix eval -f default.nix```. Note that nix eval behaves as ```--strict``` (tries to evaluation the entire result).
- ```nix-prefetch-url```
- ```nix-store```

- Use [```nix repl```](https://nixos.wiki/wiki/Nix_command/repl) to interactively explore the Nix language as well as configurations, options and packages.
  - Video: [Running Nix Code: nix eval and nix repl](https://www.youtube.com/watch?v=9kXahFVnFqw&list=WL&index=271).

   ![](docs/img/various/nixrepl.png)

    ````
    $ nix repl
    Welcome to Nix 2.15.0. Type :? for help.

    nix-repl>  
    ````
  - Use ```:?``` to get help on the commands 
  - Use ```:q``` to quit nix-repl.
    
  - You can use autocomplete (tab, tab) from within nix-repl.
  - Get the documentation of a [built-in function](https://nixos.org/manual/nix/stable/language/builtins.html) ```:doc```, for instance:
    ```
    nix-repl> :doc dirOf
    ```
  - Show the logs for a derivation use ```:log```, for instance:
      ```
      nix-repl> builtins.readFile drv
      "Hello world"
      nix-repl> :log drv
      Hello world
      ```

  - load nixos configuration from a nix file (not Flake):
    ```
    $ nix repl --file '<nixpkgs/nixos>' -I nixos-config=./configuration.nix
    ```

  - Add everything that you see passed to modules: options, config, pkgs, lib, and the other "Special ones":
    ```
    $ nix repl>:l <nixpkgs/nixos>
    ```
  - Similarly on Flake systems:
    ```
    $ nix repl>:lf /etc/nixos
    $ nix repl>nixosConfigurations.<hostname>
    ```


- Garbage collection:
  - Ref. the options ```keep-derivations``` (default: ```true```) and ```keep-outputs``` (default: ```false```) in the Nix configuration file.
  - ```nix-collect-garbage --delete-old```: Quick and easy way to clean up your system, deletes **all** old generations of **all** profiles in ```/nix/var/nix/profiles```. See the other options below for a more "surgical" way to garbage collect.
  - ```nix-env --delete-generations old```: Delete all old (non-current) generations of your current profile.
  - ```nix-env --delete-generations 10 11 23```: Delete a specific list of generations
  - ```nix-env --delete-generations 14d```: Delete all generations older than 14 days.
  - ```nix-store --gc --print-dead```: Display what files would be deleted.
  - ```nix-store --gc --print-live```: Display what files would not be deleted. 
  - After removing appropriate old generations (after having used ```nix-env``` with an argument ```--delete-generations```) - you can run the garbage collector as follows: ```nix-store --gc```

## Nix debugging
  - ```lib.debug.traceSeq <arg1> <arg2>```: Print a fully evaluated value.
## Common bitcoin-related commands
- [bitcoin-cli](https://en.bitcoin.it/wiki/Original_Bitcoin_client/API_calls_list)
- Pipe the output of ```bitcoin-cli``` through ```jq```, for instance:
  - ```$ bitcoin-cli getblockchaininfo | jq '.'``` to get pretty JSON output formatting.
  - ```$ bitcoin-cli getblockchaininfo | jq '.verificationprogress'```
- ```bitcoin-cli -addrinfo```
- ```bitcoin-cli -getinfo```
- Bitcoin-cli to execute bitcoin RPC commands ([full list](https://en.bitcoin.it/wiki/Original_Bitcoin_client/API_calls_list)), some of the most commonly used commands are:
- ``General Info```
  - ```bitcoin-cli help```
  - ```bitcoin-cli help getblockchaininfo```
  - ```bitcoin-cli getblockchaininfo```
  - ```bitcoin-cli getpeerinfo```
  - ```bitcoin-cli getnetworkinfo```
  - ```bitcoin-cli getmininginfo```
  
- Block Info
  - ```bitcoin-cli getblockcount```
  - ```bitcoin-cli getbestblockhash```
  - ```bitcoin-cli getblock hash```
  - ```bitcoin-cli getblockhash index```
- Transaction Info
  - ```bitcoin-cli getwalletinfo```
  - ```bitcoin-cli createwallet```
  - ```bitcoin-cli listreceivedbyaddress 0 true```: List of accounts on the system.
  - ```bitcoin-cli setaccount 1GBykdD628RbYPr3MUhANiWchoCcE52eW2 myfirstaccount```: To associate an existing address (here : 1GBykdD628RbYPr3MUhANiWchoCcE52eW2) to an account name.
  - ```bitcoin-cli sendfrom myfirstaccount 1AYJyqQHCixxxxxxffevxxxxQosCWqn1bT 0.15```: Send bitcoins (here : 0.15) to an address (here : 1AYJyqQHCixxxxxxffevxxxxQosCWqn1bT) 
  - ```bitcoin-cli getrawmempool```
  - ```bitcoin-cli getrawtransaction txid```
  - ```bitcoin-cli decoderawtransaction rawtx```

## Common clightning-related commands
- [clightning-cli](https://en.bitcoin.it/wiki/Original_Bitcoin_client/API_calls_list): lightning-cli simply uses the JSON RPC interface to talk to lightningd, and prints the results.
- Complete list of all JSON-RPC commands: [HERE](https://docs.corelightning.org/docs/api-reference)
- Simple examples:
  ```
  $ lightning-cli --version
  $ lightning-cli help
  $ lightning-cli getchaininfo
  $ lightning-cli getinfo
  ```

## Podcasts
- [Citadel Dispatch #37, Sep 2021](https://fountain.fm/episode/4VMvLwI6VXY5uG4xJhfu): Building software from source code, reproducible builds, reducing trust, coin selection, coin control, coinjoin
- [Citadel Dispatch #42, Nov 2021](https://fountain.fm/episode/sPtROvlhO5v6niLY8fvy): Security focused bitcoin nodes with @nixbitcoinorg, @n1ckler, and @seardsalmon
- [nixbitcoin-dev with Stefan Livera](https://stephanlivera.com/episode/195/): A security focused bitcoin node.


## Connext projects / references
- [Seed-signer](https://github.com/SeedSigner/seedsigner/blob/dev/README.md): Bitcoin only, open source, offline, airgapped Bitcoin signing device. Can also DIY.
- [Blockstream Jade](https://github.com/Blockstream/Jade/blob/master/README.md): Bitcoin only, open source hardware wallet. Can also DIY.
- Hardware Wallets [comparison and audit](https://cryptoguide.tips/hardware-wallet-comparisons/).
- [BIP39](https://iancoleman.io/bip39/): Play around and understand 12 vs 24 word seed (mnemonic) length, does it make a difference? Entropy, splitting scrambling ... (don't forget to generate a random mnemonic and select the option "Show split mnemonic cards" to see how much time it would take to brute-force attack).
  ![](docs/img/various/12_24_mnemonic_split.png)
- Other package managers:
  - Homebrew
    - $ brew search android-platform-tools
    - $ brew install android-platform-tools
    - $ brew info android-platform-tools
    - $ brew remove android-platform-tools
  - apt
  - Tea
## Federations
- FEDIMINT (by Fedi):
  - Explanation video by Obi and Justin (Bitcoin Miami 2023): [https://www.youtube.com/watch?v=_ByXD659Tcc]().
  - Fedimint on [GitHub](https://github.com/fedimint).
  - Telegram: 
    - [@fedimint](https://t.me/fedimint)
    - [@fedibtc](https://t.me/fedimint)
  - [Discord](https://discord.gg/zwQhqBqq).
 - LIQUID (by Blockstream)
    - ...  
    - ..


## For developers
  - Great Nix language tour: https://nixcloud.io/tour
  - [Poetry2nix](https://www.tweag.io/blog/2020-08-12-poetry2nix/): Developping Python with Poetry & Poetry2Nix: Reproducible, flexible, Python environments.
  - [The difference between RPC and REST](https://nordicapis.com/whats-the-difference-between-rpc-and-rest/)
  - [Polar](https://lightningpolar.com/): One-click Bitcoin Lightning Networks for local app development & testing.
  - [Rust](https://www.rust-lang.org/): Multi-paradigm, general-purpose programming language that emphasizes performance, type safety, and concurrency. It enforces memory safety—ensuring that all references point to valid memory—without requiring the use of a garbage collector or reference counting present in other memory-safe languages.
  - [Cargo](https://doc.rust-lang.org/cargo/): Package manager for Rust.
  - [Just](https://just.systems/man/en/): Just is a handy little tool to save and run project-specific commands.
    ![](docs/img/various/just_tool.png)
  - [DuckDNS](https://www.duckdns.org/): Allows to get free dynamic DNS (forces 'KYC' by login using Github, Twitter, reddit or Google account). Good for testing.
  - How to compile Bitcoin Core and run the unit and functonal tests: https://jonatack.github.io/articles/how-to-compile-bitcoin-core-and-run-the-tests
  - [asciinema](https://asciinema.org/): Record and share your terminal sessions, the simple way.
## Books
- [Introduction to the Mac command line](https://github.com/ChristopherA/intro-mac-command-line) (on GitHub).
- [Learn Bitcoin from the command line](https://github.com/BlockchainCommons/Learning-Bitcoin-from-the-Command-Line#readme) (on GitHub)
- [Mastering the Lightning Network](https://github.com/lnbook/lnbook#readme) (on GitHub).
- [The NixOS and Flakes book](https://nixos-and-flakes.thiscute.world/introduction/): The NixOS and Flakes book.
- [How to make a mint](https://groups.csail.mit.edu/mac/classes/6.805/articles/money/nsamint/nsamint.htm): The Cryptography of anonymous electronic cash (18 June 1996).
## 

- **Crypto Pals**
  - Page: [www.cryptopals.com](https://www.cryptopals.com/). Be scared of the emerged part of the iceberg in cryptography. Take this challenge!
- **The Declaration of Independence of Cyberspace (John Perry Barlow)**
  - Document: [https://cryptoanarchy.wiki/people/john-perry-barlow](https://cryptoanarchy.wiki/people/john-perry-barlow)
  - Audio, red by the author: [https://www.youtube.com/watch?v=3WS9DhSIWR0](https://www.youtube.com/watch?v=3WS9DhSIWR0)
- **Users Manual for The Human Experience (Michael W. Dean)** 
  - pdf book: [https://michaelwdean.com/UMFTHE/Users_Manual_for_The_Human_Experience-eBook.pdf](https://michaelwdean.com/UMFTHE/Users_Manual_for_The_Human_Experience-eBook.pdf)
  - audiobook on YouTube: https://www.youtube.com/watch?v=xpJMFBpGR2s
- **How Learning Works (Published by Jossey-Bass)**
  - Document: [https://firstliteracy.org/wp-content/uploads/2015/07/How-Learning-Works.pdf](https://firstliteracy.org/wp-content/uploads/2015/07/How-Learning-Works.pdf)
