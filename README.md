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

If you have to build the image, this will take about 10-20 minutes even with a good internet connection.

## Quick Start

```
./grasshopper
```

## Usage

```
Usage: ./grasshopper [OPTIONS]
OPTIONS:
  -b    Rebuild the container before running (don't do this)
  -h    Print this usage message and exit
  -k    Kill any containers that exist before running


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
  - radare2 tool suite
  - SecLists wordlists (found under /data/wordlists)
  - pwntools
  - python3
  - qemu user emulation binaries
  - strace
  - vim/neovim with useful plugins
  - much, much more!
```
