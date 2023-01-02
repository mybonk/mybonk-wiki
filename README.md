# MYBONK CORE


## Table of Contents

  - TBD
  - TBD
  -   TBD
  -   TBD
  - TBD

## Features

* Plug anf forget
* Replace one console for another
* non-custodial
* Simplified and hardened software stack

## Installation of the ecosystem (1 administration machine and 2 MYBONK full nodes)
Build of the administration machine: 
It can be any laptop you use every day. It is not have to be running nixOS as it is not one of the full nodes in the ecosystem. 
You could use you own day to day laptop but nix installs quite a few things deep in the system so I prefer to use a minimal Debian Linux image on a VirtualBox on my laptop this way it does not "polute" or changes anything on my laptop. Linux Debian is  used in these steps, adjust accordingly if you decide to use something else:
1. Install VirtualBox (https://www.virtualbox.org/) on your laptop
2. Download the image you will be using, you can either:
      Use the default "small image" from Debian (https://www.debian.org/distrib/), using this method you will go through the steps of installing the OS from scratch from the bootlable installation image that you will have to copy on a USB stick using BalenaEtcher and boot your virtual machine in Virtual Box.
      Use a pre-built VDI (Virtual Box Image) Debian built specifically to run on VirtualBox (e.g. https://www.osboxes.org/debian/): Download and run immediatly within VirtualBox
3. Now you can install nix package manager on this brand new "administration machine"


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

