FROM debian:stable-slim

# environment variables
ENV DEBIAN_FRONTEND="noninteractive"
ENV HOME="/root"
ENV XDG_DATA_HOME="/root/.config"
ENV LANG C.UTF-8
ENV LC_ALL="en_US.UTF-8"
ENV LC_CTYPE="en_US.UTF-8"
ENV TERM="xterm-256color"
ENV SHELL="/bin/bash"

# build variables
ARG BINWALK="https://github.com/devttys0/binwalk.git"
ARG DOCKER_VER="docker-26.1.1.tgz"
ARG GDB="gdb-13.0.50.20221218"
ARG GDB_EXT=".tar.xz"
ARG HOME="/root"
ARG MSF="https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb"
ARG MSF_PATH="/opt/metasploit-framework/bin"
ARG MSF_SCRIPT="msfinstall"
ARG R2="https://github.com/radareorg/radare2.git"
ARG R2_PATH="/radare/radare2/sys"
ARG R2_PLUGINS="r2ghidra esilsolve r2ghidra-sleigh"
ARG RSACTFTOOL="https://github.com/RsaCtfTool/RsaCtfTool.git"
ARG RUST_PATH="${HOME}""/.cargo/bin"
ARG PIP_FILE="${HOME}""/requirements.txt"
ARG SASQUATCH="https://github.com/devttys0/sasquatch"
ARG SECLISTS="https://github.com/danielmiessler/SecLists.git"
ARG WORDLIST_DIR_MAIN="/data/wordlists"
ARG WORDLIST_DIR_LINK="/usr/share/wordlists"
ARG ROCKYOU_PATH="${WORDLIST_DIR_MAIN}""/Passwords/Leaked-Databases"

WORKDIR /tmp 

# Add configurations
COPY ./configs/* "${HOME}"/
COPY ./configs/.* "${HOME}"/
COPY ./configs/.config "${HOME}"/.config

# Overwrite sources.list
# COPY ./apt_config/sources.list /etc/apt/sources.list

# Update everything
# Also, add the archs we want for QEMU here
RUN dpkg --add-architecture i386 &&\
    dpkg --add-architecture arm64 &&\
    apt -y update  &&\
    apt -y upgrade &&\
    apt -y install libc6:arm64 locales

# Add a bunch of random things we may need from apt.
# For some reason, when I try to install too much at once,
# I get apt errors. Splitting up the installs also help us 
# identify where an install issue is, so let's break it up:

# Start with some random things we need
RUN apt -y install\
    bat\
    ca-certificates\
    file\
    git\
    gnupg\
    locales\
    software-properties-common\
    tmux\
    trash-cli &&\
    mkdir -p ~/.local/share/Trash

# Fix our locale
RUN sed -i '/^#.*en_US.UTF-8.*/s/^#//' /etc/locale.gen &&\
    dpkg-reconfigure locales &&\
    locale-gen en_US.UTF-8 &&\
    dpkg-reconfigure locales

# Next, networking tools
RUN apt -y install\
    curl\
    netcat-openbsd\
    net-tools\
    nmap\
    subnetcalc\
    wget

# Next, some programming tools
RUN apt -y install\
    clang\
    make\
    ruby &&\
    gem install bundler

# Next, some libraries we need
RUN apt -y install\
    libexpat1-dev\
    libgmp-dev\
    liblzma-dev\
    liblzo2-dev\
    libmpfr-dev

# Next, some things we need for hacking.
# We have to split some of these out individually 
# since some of these packages are huge

# Part 1 (random tools)
RUN apt -y install\
    apt-file\
    asciinema\
    checksec\
    elfutils\
    hashcat\
    hexedit\
    patchelf\
    postgresql\
    procps
    
# Part 2 (sagemath by itself)
RUN apt -y install\
    sagemath
    
# Part 3 (qemu full and user)
# (changed qemu to qemu-system for debian)
RUN apt -y install\
    qemu-system\
    qemu-user-static
    
# Part 4 (remaining packages)
RUN apt -y install\
    strace\
    wine\
    xz-utils

# Let's decide what archs we want in the container
# by default. Users can install additional ones
# as needed since the packages are relatively small
RUN apt -y install\
    binutils-aarch64-linux-gnu

# Add NodeJS
RUN cd /tmp &&\
    curl -sL install-node.vercel.app/lts > ./lts &&\
    chmod +x ./lts &&\
    ./lts --yes &&\
    rm -rf ./lts

# Add text editors and configurations
RUN apt -y install vim neovim &&\
    curl -fLo\
    ~/.config/nvim/autoload/plug.vim --create-dirs\
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim &&\
    nvim +PlugInstall +q +UpdateRemotePlugins +q

# Add everything we will probably need with python
# and update PATH now to avoid issues in the future
ENV VIRTUAL_ENV="${HOME}""/""${VENV}"
ARG VENV="prophesy"
ENV PATH="${VIRTUAL_ENV}""/bin:""${HOME}""/bin:""${RUST_PATH}"":""${PATH}"

RUN apt -y install\
    python3\
    python3-pyelftools\
    python3-pycryptodome\
    python3-gmpy2\
    python3-dev\
    python3-distutils\
    python3-pip\
    python3-venv &&\
    python3 -m venv "${VIRTUAL_ENV}"

COPY ./requirements.txt "${PIP_FILE}"
RUN python3 -m pip install -r "${PIP_FILE}" &&\
    rm -rf "${PIP_FILE}"

# Add GEF to GDB
# Sadly, we have to install GDB ourselves for python support
RUN cd /tmp &&\
    git clone https://github.com/hugsy/gef.git &&\
    echo source `pwd`/gef/gef.py >> ~/.gdbinit &&\
    git clone https://github.com/scwuaptx/Pwngdb.git --depth 1 ~/Pwngdb &&\
    cat ~/Pwngdb/.gdbinit >> ~/.gdbinit

RUN cd /tmp &&\
  wget https://sourceware.org/pub/gdb/snapshots/current/${GDB}${GDB_EXT} &&\
  tar xvf "${GDB}""${GDB_EXT}" &&\
  cd "${GDB}" &&\
  ./configure --with-python=/usr/bin/python3 &&\
  make -j `nproc` &&\
  make install &&\
  cd /tmp &&\
  rm -rf /tmp/"${GDB}"*

# Install binwalk
RUN cd /tmp &&\
    git clone "${BINWALK}" --depth 1 &&\
    cd ./binwalk &&\
    ./setup.py install &&\
    rm -rf /tmp/binwalk

# Binwalk requires sasquatch, which must be built separately
# The patch that is required fixes a "if statement not guarded" error.
# I have no idea why this happens, and this solution I just found online.
# No reason to trust it outside of the container...
RUN cd /tmp &&\
    git clone "${SASQUATCH}" &&\
    wget https://raw.githubusercontent.com/devttys0/sasquatch/82da12efe97a37ddcd33dba53933bc96db4d7c69/patches/patch0.txt &&\
    mv -f ./patch0.txt ./sasquatch/patches/patch0.txt &&\
    cd ./sasquatch &&\
    ./build.sh &&\
    rm -rf /tmp/sasquatch

# Install wordlists
RUN cd /tmp &&\
    git clone "${SECLISTS}" &&\
    mkdir -p /data/ /usr/share/ &&\
    cp -r /tmp/SecLists "${WORDLIST_DIR_MAIN}" &&\
    ln -sf "${WORDLIST_DIR_MAIN}" "${WORDLIST_DIR_LINK}" &&\
    cd "${ROCKYOU_PATH}" &&\
    tar -xzf rockyou.txt.tar.gz

# Install metasploit
RUN curl -fsSL https://apt.metasploit.com/metasploit-framework.gpg.key |\
    gpg --dearmor |\
    tee /usr/share/keyrings/metasploit.gpg > /dev/null

RUN echo "deb [signed-by=/usr/share/keyrings/metasploit.gpg] http://downloads.metasploit.com/data/releases/metasploit-framework/apt lucid main" |\
    tee /etc/apt/sources.list.d/metasploit.list &&\
    apt update -y &&\
    apt install -y metasploit-framework

# Install Radare2
# We have to keep the source dir around, so put it somewhere permanent
RUN mkdir /radare &&\
    cd /radare &&\
    git clone "${R2}" &&\
    cd "${R2_PATH}" &&\
    ./install.sh

# Install r2 plugins
RUN r2pm -ci $R2_PLUGINS

# Install and link RsaCtfTool
# We have to keep this source dir around, as well
RUN cd / &&\
    git clone "${RSACTFTOOL}" &&\
    ln -s /RsaCtfTool/RsaCtfTool.py /usr/local/bin/RsaCtfTool

# Install rust and rust tools we like 
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o rustup.sh &&\
    sh ./rustup.sh -y &&\
    rm -rf ./rustup.sh
    
RUN rustup update
RUN cargo install pwninit
RUN cargo install rustscan
RUN cargo install --git https://github.com/asciinema/agg

# Install Docker inside of Docker
RUN wget https://download.docker.com/linux/static/stable/x86_64/docker-26.1.1.tgz &&\
    tar xzvf /tmp/"${DOCKER_VER}" &&\
    cp /tmp/docker/* /bin/ &&\
    dockerd &
    
# Update the apt-file database
RUN apt-file update
    
WORKDIR "${HOME}""/workbench"

# Cleanup
RUN apt clean &&\
    rm -rf /var/lib/apt/lists/* /var/tmp/*
#    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
