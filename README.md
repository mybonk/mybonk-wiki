# MYBONK CORE


## Table of Contents

  <to be done>

## Forewords
Welcome in our rabbit hole. 
You arrived here for a reason. Read this document from the beginning to the end once, then read it again before you are ready to getting your hands dirty. We took a great attention editing this document with reference links to make it as straightforward and easy to follow as possible
You can contribute to the documentation if you have a GitHub account (if not why not create one): Just fork the project on your machine or simply correct little typos using GitHub's built-in edit built-in capabilities. 

## Terminology
- MYBONK user: Merchant, family man, citadel, institution, bank .etc.. Just want it to work "plug and forget". Only use web-based GUIs. On MAINNET.
- MYBONK operator: A "MYBONK hacker" that got really hooked and decided to learn more, has some "skin in the game". On MAINNET.
- MYBONK hacker: Student, Maker, researcher. Just want to tear things apart. Love using only the terminal. On SIGNET.

- MYBONK console: A full-node bitcoin-only hardware platform designed with price, performance, durability, environment, supply chain resilience and generic parts in mind.
- MYBONK core: Tailor-made full-node software stack for MYBONK console (although it can run on pretty much any hardware if you are ready to tune and hack a little bit). MYBONK core is based on nix-bitcoin itself based on nixOS. 

## Overview

This small ecosystem consists in the build of 2 elements, a detailed section explains how to set them up, follow these instructions carefully.
- 1 orchestration machine: 
  This machine is used to orchestrate your fleet of MYBONK consoles, it is essentially a Linux with a few additional software installed including the nix package manager.
- 1 MYBONK console: 
  This machine runs the MYBONK stack. It is setup once and its configuration can be updated remotly using the orchestration machine.
  You could generate as many MYBONK consoles as you want as easily, it's the goal, but let's keep this simple here.
  
Take a deep breath.

## Ready, steady, go!

IMPORTANT: 
- Don't trust, verify: Anything you download on the internet it at risk of being malicious software. Know your sources. Always run the GPG (signature) or SHA-256 (hash) verification (typically next to the download link of an image or package there is a sting of hexadecimal characters, it's no decoration).
- It is very important to understand the concept that nix and nixOS two different things: nix is a [package manager](https://en.wikipedia.org/wiki/Package_manager) (something like npm, rpm and others) whereas nixOS is a [full-blow Linux distribution](https://en.wikipedia.org/wiki/NixOS) built on top of the nix package manager.

### Build the "orchestration" machine
This machine is used to manage your fleet of MYBONK consoles.
It does not have to run nixOS (only nix package manager), you could use your day to day laptop but nix installs quite a few things deep in the system and I like to keep things separate. 
A basic Linux image in VirtualBox on your laptop is perfect for this: The steps hereafter are based on Linux Debian, adjust accordingly if you decide to do differently:
####1. Download and install VirtualBox (https://www.virtualbox.org/)
####2. Build the OS: There are 2 options:
  ##### OPTION 1: Use a default installation image from Debian (https://www.debian.org/distrib/)
      ..*With this method you go through the standard steps of installing the Debian OS in VirtualBox just as if you were installing it on a new desktop.
      ..* Don't forget to take note of the the machine's IP address and login details you choose during the installation!
      ..* Detailed instructions here: https://techcolleague.com/how-to-install-debian-on-virtualbox/
  ##### OPTION 2: Use a ready-made Virtual Box VDI (Virtual Disk Image). 
  ..*The process is much quicker and more convenient than OPTION 1 as we use a pre-installed Debian System. 
  ..*Example: https://www.linuxvmimages.com/images/debian-11/ the login details are typically on the same page as the download link. 
  ..*Do not use such images in a production environment. 
  ..*It is possible you get 'Loggin incorrect' when trying to ssh in the box. This is a common issue when using a certain language's OS with another language's keyboard (e.x. QWERTY vs AZERTY) there are various easy ways to work around this that are out of the scope of this document. The simplest and effective is to find a way to login with the keyboard you have anyways until you figure out which key is which then once logged-in you can ajust the settings in "Region & Language" > "Input Source" using the mouse in Gnome or KDE.
####3. Install the nix packages: There are 2 options:
     ##### OPTION 1: Build Nix from source, follow the instructions at https://nixos.org/nix/manual/#ch-installing-source
     ##### OPTION 2: Install from nixos.org repository. 
     ..*This is quicker and more convenient for test environments.
      
      ssh into the machine:
      Install nix:
      ```
      $ sh <(curl -L https://nixos.org/nix/install) --daemon
      ```
      
      Note: If you prefer to build the system from source instead of copying binaries from the Nix cache, add the following line to /etc/nix.conf



      




### Build of the MYBONK full nodes:

<TBD>
<TBD>
<TBD>
  
  Example: To check the hash of downloaded_image.iso
      ```
      $ sha256sum downloaded_image.iso
      f4732241c03516184452f115e102a683a5282030a65b936328245a4d0ca064d2 sha256sum downloaded_image.iso
      ```




## Software Stack

Is refered to as a "softawre stack" the group of software bundled together. This eases deployment and allow people to use a baseline to contribute from.
MYBONK stack is composed of:

- **GitHub**  [details](<https://www.wikipedia.org/wiki/HitHub)>
  - Description: Nix is a tool that takes a unique approach to package management and system configuration.
  - Official: https://github.com
- **Nix/NixOS**
  - "Reproducible, declarative and reliable systems."
  - Description: Nix is a tool that takes a unique approach to package management and system configuration.
  - Official: https://nixos.org
  - Code: https://github.com/NixOS/
- **bitcoind**
  - Description: This is bitcoin.
  - Official: https://bitcoin.org/
  - Code: https://github.com/bitcoin/bitcoin
- **c-lightning**
  - Description: This is Lightning Network (LN)
  - Official:  [https://docs.lightning.engineering/lightning-network-tools/lnd](https://blockstream.com/lightning/)
  - Code: https://github.com/elementsproject/lightning#getting-started
- **nginx**
  - Description: Reverse-proxy to route the requests to internal services
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
- **LNBits**
  - Description: This allows for great bitcoin/LN advanced features through APIs and plugins architecture.
  - Official: https://lnbits.com
  - Code: https://github.com/lnbits/lnbits
- **John Perry Barlow: The Declaration of Independence of Cyberspace**
  - Document: [https://cryptoanarchy.wiki/people/john-perry-barlow](https://cryptoanarchy.wiki/people/john-perry-barlow)
  - Audio, red by the author: [https://www.youtube.com/watch?v=3WS9DhSIWR0](https://www.youtube.com/watch?v=3WS9DhSIWR0)

