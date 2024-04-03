# Grasshopper

```
I tailored the age to fit me.
We walked to the south, raising dust above the steppe;
The tall weeds fumed; the grasshopper danced,
Touching its antenna to the horse-shoes - and it prophesied,
Threatening me with destruction, like a monk.
I strapped my fate to the saddle;
And even now, in these coming times,
I stand up in the stirrups like a child.
```

A CTF container that only requires any modern version of Bash and (almost)
any modern version of Docker.

If everything works as expected, you should be able to just run `./grasshopper` to get started.

If you have to build the image, this will take about 30 minutes even with a good internet connection.

## Quick Start

```
./grasshopper
```

## Usage

```
Usage: ./grasshopper [OPTIONS]
OPTIONS:
  -b    Just build the container and exit (this can take 30 minutes)
  -d    Build the container before running (this can take 30 minutes)
  -h    Print this message and exit
  -k    Kill any containers that exist before running
  -l    Run and exec into a locally built container. NOTE:
        This could require building the image itself, which can take
        up to 30 minutes. This option should only be used for testing
  -x    Kill any containers and exit

Grasshopper is intended to be a temporary workbench for solving
CTF challenges. The 'workbench' is host volume mounted so you can
copy files from your host into it and interact with them from the
container and vice versa. This is your starting point when executing
the container. This directory can be moved or deleted or cleaned out
(such as moving the challenges you worked on after a CTF out of it)
without any issues. Grasshopper includes several tools, but here are
some of the highlights:
  - angr
  - binwalk
  - gdb with gef
  - hashcat
  - nmap
  - pwntools
  - python3
  - qemu user emulation binaries
  - radare2 tool suite
  - SecLists wordlists (found under /data/wordlists)
  - strace
  - vim/neovim with useful plugins
  - much, much more!

If you run Grasshopper with no arguments, it will either exec into
the container if it is already running, or it will first run the
container and then exec into it. If the image isn't found in your
local registry, it will first pull the image, then run it, then
exec into it.
```

## Additional Notes

It is a known problem that Docker containers that run as with the 
`root` user inside of the container can lead to permissions problems.
This is particularly troublesome when we are running host-mounted
volumes, since you can just create a special file owned by root on 
the host machine you are running a docker container on.

I don't have any novel ways to address this, so I am just assuming
that if you are running `grasshopper`, you are running it on a machine 
you own.

Additionally, I haven't found an elegant way to create
user-who-started-the-process owned files on the host from within the
Docker image. They will appear as root, always. If I can find an elegant 
solution to this, I will add it immediately, but currently the only
workaround seems to involve created a dummy user in the Dockerfile or a 
bash script -- both of which would add unneeded complexity to `grasshopper`.

In the meantime, this means you will have to copy files you want inside 
the docker container to the host-mounted volume path with `sudo`. This 
isn't ideal, but it is the best solution I have now. Obviously, from the 
host, you can make any changes to the files you want (assuming you have 
`root`).

## v1.3

- Added patchelf 
- Added rust, rustmap, and pwninit 
- Added sagemath
- Added RsaCtfTool
- Binwalk extraction for squashfs was broken. Installed patch version of sasquatch to fix this
- Full update and upgrade of binaries
- Updated metasploit to use apt. The install script was broken for me

### Additional v1.3 Update Notes

The size of the image has blown up to just under 18GB. The process of building is time consuming and error prone since some of the installs take a lot of time and Docker seems to throw random errors if a single process lingers around too long. Basically, what we are getting at here is that we can no longer sanely recommend building locally, and we very likely will remove this option from the script in the next release. The option is retained at the moment, since we want people to be able to customize thei grasshopper Dockerfile, but, if this isn't done in advance, you could spend more than an hour building (the build takes 20-30 minutes, but if you encounter timeouts or errors, you just have to try again, which I have had to do 3 or 4 times in the past).
