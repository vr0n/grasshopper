# syntax=docker/dockerfile:1
#
# Grasshopper — a disposable CTF workbench for humans and LLM agents.
#
# Multi-stage build:
#   * rust-builder  : compiles the Rust CTF tools, ships only the binaries
#                     (the ~1.5GB Rust toolchain is left behind).
#   * final         : Debian + apt/pip/source tooling, with the builder
#                     binaries copied in.
#
# Build/runtime notes:
#   * GDB comes from apt (it already has Python support for GEF) instead of a
#     ~20-minute source compile.
#   * Each apt phase cleans /var/lib/apt/lists to keep layers small.

############################
# Stage 1: Rust CTF tools  #
############################
FROM rust:1-slim-bookworm AS rust-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        make \
        pkg-config \
        libssl-dev \
        liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# CARGO_HOME defaults to /usr/local/cargo in the official rust image, so the
# resulting binaries land in /usr/local/cargo/bin.
RUN cargo install pwninit rustscan \
    && cargo install --git https://github.com/asciinema/agg

############################
# Stage 2: Final image     #
############################
# Pinned to bookworm (not debian:stable): trixie/Debian 13 dropped sagemath and
# python3-distutils, both of which the CTF toolset relies on. Pinning also keeps
# the build reproducible.
FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="grasshopper" \
      org.opencontainers.image.description="Disposable CTF workbench for humans and LLM agents" \
      org.opencontainers.image.source="https://github.com/vr0n/grasshopper"

# environment variables
ENV DEBIAN_FRONTEND="noninteractive" \
    HOME="/root" \
    XDG_DATA_HOME="/root/.config" \
    LANG=C.UTF-8 \
    LC_ALL="en_US.UTF-8" \
    LC_CTYPE="en_US.UTF-8" \
    TERM="xterm-256color" \
    SHELL="/bin/bash"

# build variables
ARG HOME="/root"
ARG VENV="prophesy"
ARG BINWALK="https://github.com/devttys0/binwalk.git"
ARG MSF="https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb"
ARG R2="https://github.com/radareorg/radare2.git"
ARG R2_PLUGINS="r2ghidra esilsolve r2ghidra-sleigh"
ARG RSACTFTOOL="https://github.com/RsaCtfTool/RsaCtfTool.git"
ARG SASQUATCH="https://github.com/devttys0/sasquatch"
ARG SECLISTS="https://github.com/danielmiessler/SecLists.git"
ARG WORDLIST_DIR_MAIN="/data/wordlists"
ARG WORDLIST_DIR_LINK="/usr/share/wordlists"
ARG ROCKYOU_PATH="${WORDLIST_DIR_MAIN}/Passwords/Leaked-Databases"
# TARGETARCH is auto-provided by buildkit (amd64, arm64, ...) and matches Go's
# arch naming, so the Go download works on both CI (amd64) and local arm64.
ARG TARGETARCH
ARG GOLANG_VER="1.22.4"
ARG JADX_VER="1.5.0"

# Put the venv on PATH up front so everything downstream resolves to it.
ENV VIRTUAL_ENV="/opt/${VENV}" \
    PATH="/opt/${VENV}/bin:${HOME}/bin:${HOME}/.local/bin:/usr/local/go/bin:${HOME}/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

WORKDIR /tmp

# Add configurations and the agent guide
COPY ./configs/ "${HOME}"/
COPY ./AGENTS.md "${HOME}"/AGENTS.md

# Enable the extra architectures we want for QEMU/multiarch work, then do the
# base update + the foundational packages, fixing the locale at the same time.
RUN dpkg --add-architecture i386 \
    && dpkg --add-architecture arm64 \
    && apt-get update && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libc6:arm64 \
        locales \
    && sed -i '/^#.*en_US.UTF-8.*/s/^#//' /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Core utilities, networking, build, and library tooling.
RUN apt-get update && apt-get install -y --no-install-recommends \
        bat \
        file \
        git \
        gnupg \
        tmux \
        trash-cli \
        wget \
        curl \
        netcat-openbsd \
        net-tools \
        nmap \
        subnetcalc \
        clang \
        build-essential \
        make \
        ruby \
        libexpat1-dev \
        libgmp-dev \
        liblzma-dev \
        liblzo2-dev \
        libmpfr-dev \
    && gem install bundler \
    && mkdir -p ~/.local/share/Trash \
    && rm -rf /var/lib/apt/lists/*

# CTF tooling from apt. GDB here is the packaged build (has Python for GEF).
RUN apt-get update && apt-get install -y --no-install-recommends \
        apt-file \
        asciinema \
        checksec \
        elfutils \
        gdb \
        hashcat \
        hexedit \
        patchelf \
        postgresql \
        procps \
        strace \
        unzip \
        wine \
        xz-utils \
        binutils-aarch64-linux-gnu \
        binutils-x86-64-linux-gnu \
        binutils-i686-linux-gnu \
        vim \
        neovim \
        nodejs \
        npm \
    && rm -rf /var/lib/apt/lists/*

# Heavy, slow-to-resolve packages on their own layers (per upstream guidance
# that installing too much at once trips apt).
RUN apt-get update && apt-get install -y --no-install-recommends \
        sagemath \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
        qemu-system \
        qemu-user-static \
    && rm -rf /var/lib/apt/lists/*

# Python: build the venv and install the CTF Python stack into it.
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 \
        python3-pyelftools \
        python3-pycryptodome \
        python3-gmpy2 \
        python3-dev \
        python3-distutils \
        python3-pip \
        python3-venv \
    && python3 -m venv "${VIRTUAL_ENV}" \
    && rm -rf /var/lib/apt/lists/*

COPY ./requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --no-cache-dir -r /tmp/requirements.txt \
    && rm -f /tmp/requirements.txt

# Install Golang (kept as a runtime tool for building web/CTF helpers).
RUN GOTGZ="go${GOLANG_VER}.linux-${TARGETARCH}.tar.gz" \
    && wget -q https://go.dev/dl/${GOTGZ} \
    && tar -C /usr/local -xzf ${GOTGZ} \
    && rm -f ${GOTGZ}

# Neovim plugins (coc needs node, installed above).
RUN curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
    && nvim +PlugInstall +q +UpdateRemotePlugins +q || true

# GEF + Pwngdb for GDB.
RUN git clone --depth 1 https://github.com/hugsy/gef.git /opt/gef \
    && echo "source /opt/gef/gef.py" >> ~/.gdbinit \
    && git clone --depth 1 https://github.com/scwuaptx/Pwngdb.git ~/Pwngdb \
    && cat ~/Pwngdb/.gdbinit >> ~/.gdbinit

# Binwalk + sasquatch (patched, for squashfs extraction).
# Pinned to the last Python release; master was rewritten in Rust (no setup.py).
RUN git clone --depth 1 --branch v2.3.4 "${BINWALK}" /tmp/binwalk \
    && cd /tmp/binwalk \
    && ./setup.py install \
    && cd /tmp \
    && git clone "${SASQUATCH}" /tmp/sasquatch \
    && wget -q https://raw.githubusercontent.com/devttys0/sasquatch/82da12efe97a37ddcd33dba53933bc96db4d7c69/patches/patch0.txt \
    && mv -f /tmp/patch0.txt /tmp/sasquatch/patches/patch0.txt \
    && cd /tmp/sasquatch \
    && ./build.sh \
    && rm -rf /tmp/binwalk /tmp/sasquatch

# Wordlists (shallow clone; rockyou pre-extracted). Drop the .git metadata
# (~668MB) from the installed copy -- the wordlists themselves are unaffected.
RUN git clone --depth 1 "${SECLISTS}" /tmp/SecLists \
    && mkdir -p /data /usr/share \
    && cp -r /tmp/SecLists "${WORDLIST_DIR_MAIN}" \
    && rm -rf "${WORDLIST_DIR_MAIN}/.git" \
    && ln -sf "${WORDLIST_DIR_MAIN}" "${WORDLIST_DIR_LINK}" \
    && cd "${ROCKYOU_PATH}" \
    && tar -xzf rockyou.txt.tar.gz \
    && rm -rf /tmp/SecLists

# Metasploit (apt repo).
RUN curl -fsSL https://apt.metasploit.com/metasploit-framework.gpg.key \
        | gpg --dearmor | tee /usr/share/keyrings/metasploit.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/metasploit.gpg] http://downloads.metasploit.com/data/releases/metasploit-framework/apt lucid main" \
        | tee /etc/apt/sources.list.d/metasploit.list \
    && apt-get update && apt-get install -y --no-install-recommends metasploit-framework \
    && rm -rf /var/lib/apt/lists/*

# Radare2 built from source so r2pm plugins match the r2 version.
# Use a copy install (./configure + make install) rather than radare2's default
# sys/install.sh, which *symlinks* the binaries back into the build tree -- that
# would force us to keep the ~520MB source dir around. With a real install into
# /usr/local, the source tree, r2pm git checkouts, and the sleigh download zip
# are all build-only and removed here (~660MB) in the same layer.
# r2ghidra is the load-bearing plugin; esilsolve / sleigh can fail to build
# against bleeding-edge r2 git, so install plugins tolerantly rather than
# letting one flaky binding sink the whole image.
RUN mkdir /radare \
    && git clone --depth 1 "${R2}" /radare/radare2 \
    && cd /radare/radare2 \
    && ./configure --prefix=/usr/local \
    && make -j"$(nproc)" \
    && make install \
    && ldconfig \
    && r2pm -U \
    && for p in ${R2_PLUGINS}; do \
         r2pm -ci "$p" || echo "WARNING: r2pm plugin '$p' failed to build; skipping"; \
       done \
    && rm -rf /radare /root/.config/radare2/r2pm/git \
       /root/.config/radare2/plugins/*.zip

# RsaCtfTool installed into its own isolated venv: its pinned deps (z3-solver,
# cryptography, pycryptodome, ...) would otherwise clash with angr/pwntools in
# the main venv. The console scripts are linked onto PATH.
# z3-solver is pinned to a wheel-backed version: RsaCtfTool leaves it unpinned,
# and the latest release has no aarch64 wheel and needs C++20 <format> (gcc 13+),
# which bookworm's gcc 12 lacks -- so it would try, and fail, to build from source.
RUN git clone --depth 1 "${RSACTFTOOL}" /opt/RsaCtfTool \
    && python3 -m venv /opt/RsaCtfTool/.venv \
    && /opt/RsaCtfTool/.venv/bin/pip install --no-cache-dir \
         /opt/RsaCtfTool "z3-solver==4.13.0.0" \
    && ln -sf /opt/RsaCtfTool/.venv/bin/RsaCtfTool /usr/local/bin/RsaCtfTool \
    && ln -sf /opt/RsaCtfTool/.venv/bin/rsacrack /usr/local/bin/rsacrack

# Go-based web tools. The binaries land in /root/go/bin; clear the module and
# build caches (~560MB) afterward since they are only needed at build time.
RUN /usr/local/go/bin/go install github.com/ffuf/ffuf/v2@latest \
    && /usr/local/go/bin/go install github.com/jaeles-project/jaeles@latest \
    && /usr/local/go/bin/go clean -cache -modcache

# jadx (Android decompiler).
RUN mkdir -p /opt/jadx \
    && wget -q https://github.com/skylot/jadx/releases/download/v${JADX_VER}/jadx-${JADX_VER}.zip -O /tmp/jadx.zip \
    && unzip /tmp/jadx.zip -d /opt/jadx \
    && ln -sf /opt/jadx/bin/jadx /usr/bin/jadx \
    && rm -f /tmp/jadx.zip

# Prebuilt Rust tools copied from the builder stage (no toolchain in final).
COPY --from=rust-builder /usr/local/cargo/bin/pwninit /usr/local/bin/pwninit
COPY --from=rust-builder /usr/local/cargo/bin/rustscan /usr/local/bin/rustscan
COPY --from=rust-builder /usr/local/cargo/bin/agg /usr/local/bin/agg

# Seed the apt-file database (best done last).
RUN apt-get update && apt-file update \
    && rm -rf /var/lib/apt/lists/*

WORKDIR "${HOME}/workbench"

# Final cleanup.
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
