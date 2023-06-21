# How to burn the latest factory image on Sipeed LicheePi4A 

- Source (in progress and in Chinese, pass it through Google translate for now): https://wiki.sipeed.com/hardware/en/lichee/th1520/lpi4a/4_burn_image.html

- Board boot process is ```brom -> uboot spl -> uboot -> opensbi -> kernel```

- We will use the tool ```fastboot``` which is part of the "android tools" to burn the image (the official documentation refers to some ```burn_tool.zip``` not too sure what it is specifically but ```fastboot``` does the job):
    - Install android tools:

        ```
        $ brew install  android-platform-tools
        ```
    - The output looks like this:
        ```
        ==> Downloading https://dl.google.com/android/repository/platform-tools_r34.0.3-
        ######################################################################### 100.0%
        ==> Installing Cask android-platform-tools
        ==> Linking Binary 'adb' to '/usr/local/bin/adb'
        ==> Linking Binary 'dmtracedump' to '/usr/local/bin/dmtracedump'
        ==> Linking Binary 'etc1tool' to '/usr/local/bin/etc1tool'
        ==> Linking Binary 'fastboot' to '/usr/local/bin/fastboot'
        ==> Linking Binary 'hprof-conv' to '/usr/local/bin/hprof-conv'
        ==> Linking Binary 'make_f2fs' to '/usr/local/bin/make_f2fs'
        ==> Linking Binary 'make_f2fs_casefold' to '/usr/local/bin/make_f2fs_casefold'
        ==> Linking Binary 'mke2fs' to '/usr/local/bin/mke2fs'
        🍺  android-platform-tools was successfully installed!
        ```
        - Check it has been installed
        ````
        $ fastboot --version
        fastboot version 34.0.3-10161052
        Installed as /usr/local/bin/fastboot
        ````

- Download the latest image from the [official repository](https://mirror.iscas.ac.cn/revyos/extra/images/lpi4a/), there are 2 partitions to download:
    - The **boot** partition ```boot.ext4```, it contains:
        - fw_dynamic.bin        #opensbi
        - Image                 #kernel image
        - kernel-release        #commit id of kernel
        - light_aon_fpga.bin    #fw for E902 aon
        - light_c906_audio.bin  #fw for C906 audio
        - light-lpi4a.dtb       #1.85GHz dtb
        - light-lpi4a_2Ghz.dtb  #2GHz overclock dtb
        - light-lpi4a-ddr2G.dtb #history dtb
    - The **root** filesystem ```rootfs.ext4```, in this case a Debian system.

**in the following commands make sure you change the paths to whatever latest version available**:

    ``` 
    $ wget --no-parent -r https://mirror.iscas.ac.cn/revyos/extra/images/lpi4a/20230511/
    ```

- Navigate to the location:
    ````
    $ cd mirror.iscas.ac.cn/revyos/extra/images/lpi4a/20230511/
    ````

- Check the hash of the downloaded files (**make sure you change the filename to whatever you downloaded**), the calculated hash must match the one in ```md5sum.txt```
    ```
    $ md5sum ./boot.ext4
    e30a5ee03bf4cf0d87794908eca41767  boot.ext4

    $ md5sum ./rootfs.ext4
    776a960a4926f667adb2abfa2049872a  rootfs.ext4

    $ cat ./md5sum.txt
    e30a5ee03bf4cf0d87794908eca41767  boot.ext4
    776a960a4926f667adb2abfa2049872a  rootfs.ext4
    ```

- Burn the board:
    - Press and hold the "BOOT" button on the board while plugging the USB-C to power it. 
    - Using a tool like ```lsusb``` (on MacOS you can use [this one](https://github.com/jlhonora/lsusb#readme)) the board show up something like this ```Bus 020 Device 005: ID 2345:7654 2345 USB download gadget```.
    
    - Check and create the partitions on the flash (**burning the system will be very slow if you don't**):
        ````
        $ sudo fastboot flash ram ./u-boot-with-spl.bin
        $ sudo fastboot reboot
        $ sleep 10
        ````
        NOTE1: SPL (Secondary Program Loader) is a platform specific stage of U-Boot and should be the first in the boot chain. It can also be built from source.

        NOTE2: If ```u-boot-with-spl.bin``` is not present in the repository copy it from a previous version (parent directory).

        Which will return something like this:
        ````
        Sending 'ram' (935 KB)                             OKAY [  0.247s]
        Writing 'ram'                                      OKAY [  0.002s]
        Finished. Total time: 0.263s
        ````

    - Now burn
        ````
        $ sudo fastboot flash uboot ./u-boot-with-spl.bin
        Sending 'uboot' (935 KB)                           OKAY [  0.050s]
        Writing 'uboot'                                    OKAY [  0.027s]
        Finished. Total time: 0.123s
        ````

        ````
        $ sudo fastboot flash boot ./boot.ext4
        Sending 'boot' (61440 KB)                          OKAY [  1.626s]
        Writing 'boot'                                     OKAY [  1.348s]
        Finished. Total time: 3.012s

        ````

        ````
        $ sudo fastboot flash root ./rootfs.ext4
        Sending sparse 'root' 1/33 (113316 KB)             OKAY [  2.882s]
        Writing 'root'                                     OKAY [  2.831s]
        Sending sparse 'root' 2/33 (110992 KB)             OKAY [  2.821s]
        Writing 'root'                                     OKAY [  2.558s]
        Sending sparse 'root' 3/33 (112968 KB)             OKAY [  2.847s]
        Writing 'root'                                     OKAY [  2.599s]
        Sending sparse 'root' 4/33 (114684 KB)             OKAY [  2.886s]
        Writing 'root'                                     OKAY [  2.796s]
        Sending sparse 'root' 5/33 (114685 KB)             OKAY [  2.905s]
        Writing 'root'                                     OKAY [  2.729s]
        Sending sparse 'root' 6/33 (107685 KB)             OKAY [  2.691s]
        Writing 'root'                                     OKAY [  2.652s]
        Sending sparse 'root' 7/33 (104822 KB)             OKAY [  2.636s]
        Writing 'root'                                     OKAY [  2.683s]
        Sending sparse 'root' 8/33 (111207 KB)             OKAY [  2.805s]
        Writing 'root'                                     OKAY [  2.840s]
        Sending sparse 'root' 9/33 (113909 KB)             OKAY [  2.873s]
        Writing 'root'                                     OKAY [  2.722s]
        Sending sparse 'root' 10/33 (112400 KB)            OKAY [  2.810s]
        Writing 'root'                                     OKAY [  2.536s]
        Sending sparse 'root' 11/33 (114686 KB)            OKAY [  2.841s]
        Writing 'root'                                     OKAY [  2.842s]
        Sending sparse 'root' 12/33 (114669 KB)            OKAY [  2.871s]
        Writing 'root'                                     OKAY [  2.682s]
        Sending sparse 'root' 13/33 (113155 KB)            OKAY [  2.888s]
        Writing 'root'                                     OKAY [  3.145s]
        Sending sparse 'root' 14/33 (114685 KB)            OKAY [  2.882s]
        Writing 'root'                                     OKAY [ 12.202s]
        Sending sparse 'root' 15/33 (114684 KB)            OKAY [  2.891s]
        Writing 'root'                                     OKAY [  5.043s]
        Sending sparse 'root' 16/33 (106860 KB)            OKAY [  2.703s]
        Writing 'root'                                     OKAY [  2.406s]
        Sending sparse 'root' 17/33 (112836 KB)            OKAY [  2.840s]
        Writing 'root'                                     OKAY [  2.487s]
        Sending sparse 'root' 18/33 (109696 KB)            OKAY [  2.760s]
        Writing 'root'                                     OKAY [  2.425s]
        Sending sparse 'root' 19/33 (114032 KB)            OKAY [  2.862s]
        Writing 'root'                                     OKAY [  2.525s]
        Sending sparse 'root' 20/33 (114420 KB)            OKAY [  2.868s]
        Writing 'root'                                     OKAY [  2.578s]
        Sending sparse 'root' 21/33 (114685 KB)            OKAY [  2.886s]
        Writing 'root'                                     OKAY [  2.697s]
        Sending sparse 'root' 22/33 (114684 KB)            OKAY [  2.890s]
        Writing 'root'                                     OKAY [  2.506s]
        Sending sparse 'root' 23/33 (112276 KB)            OKAY [  2.822s]
        Writing 'root'                                     OKAY [  2.459s]
        Sending sparse 'root' 24/33 (114521 KB)            OKAY [  2.965s]
        Writing 'root'                                     OKAY [  3.279s]
        Sending sparse 'root' 25/33 (105315 KB)            OKAY [  2.750s]
        Writing 'root'                                     OKAY [  4.026s]
        Sending sparse 'root' 26/33 (114497 KB)            OKAY [  2.852s]
        Writing 'root'                                     OKAY [  2.793s]
        Sending sparse 'root' 27/33 (113492 KB)            OKAY [  2.892s]
        Writing 'root'                                     OKAY [  3.196s]
        Sending sparse 'root' 28/33 (114684 KB)            OKAY [  2.830s]
        Writing 'root'                                     OKAY [  2.530s]
        Sending sparse 'root' 29/33 (114685 KB)            OKAY [  2.911s]
        Writing 'root'                                     OKAY [  2.678s]
        Sending sparse 'root' 30/33 (114685 KB)            OKAY [  2.874s]
        Writing 'root'                                     OKAY [  2.702s]
        Sending sparse 'root' 31/33 (114138 KB)            OKAY [  2.853s]
        Writing 'root'                                     OKAY [  2.834s]
        Sending sparse 'root' 32/33 (114684 KB)            OKAY [  2.857s]
        Writing 'root'                                     OKAY [  2.626s]
        Sending sparse 'root' 33/33 (9492 KB)              OKAY [  0.252s]
        Writing 'root'                                     OKAY [  0.226s]
        Finished. Total time: 194.073s        
        ````

    Note: If you get an error message such as ```fastboot: error: ANDROID_PRODUCT_OUT not set``` it is likely that you misspelt the image filename (have you not forgotten the '.ext4'?) 

- Work "headless"
    - Means connect to your device through remote access e.x. ssh so that you don't have to keep it constantly connected to a screen.
    - ```open-ssh-server``` is not installed by default, let's do it:
        ````
        $ sudo apt update
        $ sudo apt install open-ssh-server
        $ sudo systemctl start sshd
        ````   

- Install Tailscale
    - Follow these [instructions](https://tailscale.com/download/linux/debian-bullseye).


- Benchmarking
    - Install ```curl```, ```util-linux```, ```glaces``` and ```htop```
        ````
        $ sudo install curl
        $ sudo install glances
        $ sudo install htop

        ````
    - You need ```make```installed to build Byte UNIX Bench tool next: 
        ````
        $ sudo install build-essential
        ````
    - Clone [Byte UNIX Bench](https://github.com/kdlucas/byte-unixbench/tree/master)
        ````
        $ sudo git clone https://github.com/kdlucas/byte-unixbench.git
        ````
    - Launch default test
        ````
        $ cd byte-unixbench/UnixBench
        $ ./Run
        ````
    - Now take some time to read ```byte-unixbench/UnixBench/README``` and ```byte-unixbench/UnixBench/USAGE``` the explains what tests and options are possible and how to run them. 




    

- Batch flashing
    - fastboot can be used as an offline batch burner.