# Things that really make a difference

Ordered list of "basic" skills that need to be aquired to enjoy the ride.

Go through this slowly. It is tempting to speed-read through a book, call it done, and move on to the next book. To get the most out of this, take your time understanding each section. 

For every 5 minutes you spend reading you should spend 15 minutes tinkering around with what you just read. Break things. 

The sections "Commonly used" are examples you can easily copy/past.

A good *general* cheat sheet page:  [https://github.com/ruanbekker/cheatsheets#readme](https://github.com/ruanbekker/cheatsheets#readme)


## GitHub / Git

- Fork MY₿ONK-core and clone your forked repository it on your laptop (instructions [here](https://docs.github.com/en/get-started/quickstart/fork-a-repo)).
- Commands reference [here](https://git-scm.com/docs/git).
- [Swith to another branch in terminal](https://stackoverflow.com/questions/47630950/how-can-i-switch-to-another-branch-in-git).
- [Swith GitHub account in terminal](https://dev.to/0xbf/switch-github-account-in-terminal-92g).
- Commonly used:

  ```
  git clone https://github.com/mybonk/mybonk-core.git
  git status
  git switch 
  git add
  git commit -m "commit message"
  git mv filename dir/filename
  git pull
  git push
  ```
## Command line stuff
- bash shell
- ls, cd, mkdir, mv, rm, ln, which,  …
- hostname, whoami, passwd, chmod, chgrp, …
- history 
- alias
- grep
- sudo
- file



## curl

## gpg, sha-256 …
## ssh
- [Difference between ssh and ~~Telnet~~](https://www.geeksforgeeks.org/difference-ssh-telnet/)
- [ssh: OpenSSH, how to manage ssh keys, .ssh config, ssh-keygen, ssh-agent, passphrase, ssh-add](https://goteleport.com/blog/how-to-set-up-ssh-keys/) 

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
- systemd
- top
- [journalctl](https://www.digitalocean.com/community/tutorials/how-to-use-journalctl-to-view-and-manipulate-systemd-logs)
- systemctrl

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


## UEFI vs. Legacy Boot

## Other tools / resources
- [jq](https://stedolan.github.io/jq/): Lightweight and flexible command-line JSON processor. [reference](https://stedolan.github.io/jq/tutorial/)
- [websocketd](https://github.com/joewalnes/websocketd): Small command-line tool that will wrap an existing command-line interface program, and allow it to be accessed via a WebSocket. WebSocket-capable applications can now be built very easily. As long as you can write an executable program that reads STDIN and writes to STDOUT, you can build a WebSocket server. No networking libraries necessary.
- [wscat](https://github.com/websockets/wscat/blob/master/README.md): WebSocket cat.
- [powertop](https://github.com/fenrus75/powertop/blob/master/README.md): Tool to access various powersaving modes in userspace, kernel and hardware. Monitors processes and shows which utilizes the most CPU allowing to identify those with particular high power demands.
- [tmuxinator](https://github.com/tmuxinator/tmuxinator/blob/master/README.md): Tool that allows you to easily manage tmux sessions by using yaml files to describe the layout of a tmux session, and open up that session with a single command.
![](docs/img/various/tmuxinator_screeshot.png)
- VPN
  - [Wireguard](https://www.wireguard.com/quickstart/) This VPN technology is built into the kernel; Client app widely available, allows to connect to your local network remotly using a simple QR code to authenticate.
  - [Zerotier](https://www.zerotier.com/) Another VPN alternative.
  
- Chaumian ecash system
  - [Cashu](https://cashu.space/): Cashu is a free and open-source Chaumian ecash system built for Bitcoin. Cashu offers near-perfect privacy for users of custodial Bitcoin applications. Nobody needs to knows who you are, how much funds you have, and whom you transact with.


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
  - 
