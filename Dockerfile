FROM debian:11.7

# environment variables
ENV HOME="/root"
ENV LC_ALL="en_US.UTF-8"
ENV LC_CTYPE="en_US.UTF-8"
ENV TERM="xterm-256color"
ENV SHELL="/bin/bash"
ENV VIRTUAL_ENV="${HOME}""/""${VENV}"

# build variables
ARG BINWALK="https://github.com/devttys0/binwalk.git"
ARG GDB="gdb-14.0.50.20230913"
ARG GDB_EXT=".tar.xz"
ARG HOME="/root"
ARG MSF="https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb"
ARG MSF_PATH="/opt/metasploit-framework/bin"
ARG MSF_SCRIPT="msfinstall"
ARG R2="https://github.com/radareorg/radare2.git"
ARG R2_PATH="/radare/radare2/sys"
ARG PIP_FILE="${HOME}""/requirements.txt"
ARG SECLISTS="https://github.com/danielmiessler/SecLists.git"
ARG VENV="prophesy"
ARG WORDLIST_DIR_MAIN="/data/wordlists"
ARG WORDLIST_DIR_LINK="/usr/share/wordlists"
ARG ROCKYOU_PATH="${WORDLIST_DIR_MAIN}""/Passwords/Leaked-Databases"

# Update everything
RUN dpkg --add-architecture i386 &&\
    apt -y update  &&\
    apt -y upgrade

# Add a bunch of random things we need
RUN apt -y install\
    checksec\
    clang\
    file\
    git\
    libexpat1-dev\
    libgmp-dev\
    libmpfr-dev\
    locales\
    make\
    postgresql\
    procps\
    software-properties-common\
    tmux\
    xz-utils &&\
    locale-gen en_US.UTF-8 &&\
    dpkg-reconfigure --frontend=noninteractive locales

# Add networking tools
RUN apt -y install\
    curl\
    net-tools\
    subnetcalc\
    wget

# Add configurations
COPY ./configs/* "${HOME}"/

# Add text editors and configurations
RUN apt -y install vim neovim &&\
    curl -fLo "${HOME}"/.config/nvim/autoloload/plug.vim\
    --create-dirs\
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim\
    && nvim +PlugInstall +q +UpdateRemotePlugins +q

# Add everything we will probably need with python
RUN apt -y install\
    python3\
    python3-dev\
    python3-distutils\
    python3-pip\
    python3-venv &&\
    python3 -m venv "${VIRTUAL_ENV}"

# Set this now to avoid issues in the future
ENV PATH="${VIRTUAL_ENV}""/bin:""${PATH}"

COPY ./requirements.txt "${PIP_FILE}"
RUN python3 -m pip install -r "${PIP_FILE}" &&\
    rm -rf "${PIP_FILE}"

# Add GEF to GDB
# Sadly, we have to install GDB ourselves for python support
RUN cd /tmp &&\
  wget https://sourceware.org/pub/gdb/snapshots/current/${GDB}${GDB_EXT} &&\
  tar xvf "${GDB}""${GDB_EXT}" &&\
  cd "${GDB}" &&\
  ./configure --with-python=/usr/bin/python3 &&\
  make -j `nproc` &&\
  make install &&\
  cd /tmp &&\
  rm -rf /tmp/"${GDB}"*


RUN /bin/bash -c "$(curl -fsSL https://gef.blah.cat/sh)"

# Install binwalk
RUN cd /tmp &&\
    git clone "${BINWALK}" --depth 1 &&\
    cd ./binwalk &&\
    ./setup.py install &&\
    rm -rf /tmp/binwalk

# Install wordlists
RUN cd /tmp &&\
    git clone "${SECLISTS}" &&\
    mkdir -p /data/ /usr/share/ &&\
    cp -r /tmp/SecLists "${WORDLIST_DIR_MAIN}" &&\
    ln -sf "${WORDLIST_DIR_MAIN}" "${WORDLIST_DIR_LINK}" &&\
    cd "${ROCKYOU_PATH}" &&\
    tar -xzf rockyou.txt.tar.gz

# Install hashcat
RUN apt -y install hashcat

# Install metasploit
# And run the stupidest hack ever to make msfdb "work" for us
RUN curl "${MSF}" > "${MSF_SCRIPT}" &&\
    chmod +x "${MSF_SCRIPT}" &&\
    ./"${MSF_SCRIPT}" &&\
    sed -i 's/kali/grasshopper/' "${MSF_PATH}""/msfdb" &&\
    sed -i 's/\/etc\/os-release/\/etc\/hostname/' "${MSF_PATH}""/msfdb"
    #msfdb init

# Install Radare2
# And we have to keep the source dir around, so don't delete it
RUN mkdir /radare &&\
    cd /radare &&\
    git clone "${R2}" &&\
    cd "${R2_PATH}" &&\
    ./install.sh

# Install qemu user-emulation mode things
RUN apt -y install qemu qemu-user-static

# Cleanup
RUN apt clean &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
