# MYBONK CORE


## Table of Contents

  - TBD
  - TBD
  -   TBD
  -   TBD
  - TBD

## Terminology
MYBONK conole


## Features

* Plug anf forget
* Replace one console for another
* non-custodial
* Simplified and hardened software stack

## Build of a small ecosystem (1 orchestration machine and 1 MYBONK console)

Note: Anything you download on the internet it at risk of being malicious software. Know your sources. Always run GPG verification to check conformity (typically next to the download link of an image or package there is a sting of hexadecimal characetrs, it's not decoration).

Build the "orchestration" machine
This machine is used to manage your fleet of MYBONK consoles.
It does not have to run nixOS (only nix package manager), you could use your day to day laptop but nix installs quite a few things deep in the system and I like to keep things separate. 
A basic Linux image in VirtualBox on your laptop is perfect for this: The steps hereafter are based on Linux Debian, adjust accordingly if you decide to do differently:
1. Download and install VirtualBox (https://www.virtualbox.org/)
2. Build the OS: There are 2 options:
      OPTION 1: Use the default "small image" from Debian (https://www.debian.org/distrib/): 
      With this method you go through the standard steps of installing the Debian OS in VirtualBox just as if you were installing it on a new desktop.
      Don't forget to take note of the the machine's IP address and your root account password during the installation!
      OPTION 2: Use a ready-made VDI (Virtual Box Image) of Debian (https://www.osboxes.org/debian/). This is a shortcut of OPTION 1, it does not require you to go through the Debian installation steps and contains some package for additional VirtualBox features pre-installed. Just download and run from within VirtualBox. The default credentials are username: 'osboxes'/ password: 'osboxes.org' and  root account password: 'osboxes.org' (as stated on the website).   Do not use such images in production environment.
      Make sure you can ssh in from the host system.
3. Install the nix packages: There are 2 options:
      OPTION 1: Build Nix from source, follow the instructions at https://nixos.org/nix/manual/#ch-installing-source
      OPTION 3: Install from nixos.org repository. 
      This is quicker and more convenient for test environments.
      
      sh <(curl -L https://nixos.org/nix/install) --daemon
      
      

      




... ... ...
... ... ...
... ... ...

Build of the MYBONK full nodes:





## Software Stack

Is refered to as a "softawre stack" the group of software bundled together. This eases deployment and allow people to use a baseline to contribute from.
MYBONK stack is composed of:

- **GitHub** (on this platform we can live naked) [details](<https://www.wikipedia.org/wiki/HitHub)>
- **Nix/NixOS**
  - "Reproducible, declarative and reliable systems."
  - Nix is a tool that takes a unique approach to package management and system configuration.
  - Official: https://nixos.org
  - Code: https://github.com/NixOS/
- **bitcoind**
This is Bitcoin
  - Official: https://bitcoin.org/
  - Code: https://github.com/bitcoin/bitcoin
- **lnd**
  - Description: This is Lightning Network (LN)
  - Official:  https://docs.lightning.engineering/lightning-network-tools/lnd
  - Code: https://github.com/lightningnetwork/lnd
- **LNBits (Legend)**
  - Description This allows for great bitcoin/LN advanced features. Provides great API and great plugins approach.
  - Official: https://lnbits.com
  - Code: https://github.com/lnbits/lnbits
- **nginx**
  - Description: Reverse-proxy to route the http/Tor requests to the correct internal services
  - Official: Nginx: https://nginx.org/
  - Code: https://github.com/nginx
- **Tor**
  - Official: https://www.torproject.org/
  - Code: https://www.torproject.org/download/tor/
- **Hypercore protocol**
  - Official: https://hypercore-protocol.org/
  - Code: https://github.com/hypercore-protocol
  - Learn more: https://www.ctrl.blog/entry/dht-privacy-discovery-hash.html
- **Fedimint**
  - Official: https://fedimint.org/ 
  - Code: https://github.com/fedimint

