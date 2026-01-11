project_dir := justfile_directory()
linux_distro := shell("source /etc/os-release && echo $ID")
nethack_binary := project_dir + "/src/nethack"

# print available just recipes
[group('project-agnostic')]
default:
    @just --list --justfile {{justfile()}}

# evaluate and print all just variables
[group('project-agnostic')]
just-vars:
    @just --evaluate

# print system information such as OS and architecture
[group('project-agnostic')]
system-info:
    @echo "architecture: {{arch()}}"
    @echo "os: {{os()}}"
    @echo "os family: {{os_family()}}"

# clean the build
[group('development')]
clean:
    make clean

# install dependencies after a fresh project checkout
[group('development')]
install-dependencies:
    #!/usr/bin/env bash
    # https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
    # `-e`: Immediately exit if any command 1 has a non-zero exit status
    # `-u`: Errors if a variable is referenced before being set
    # `-o pipefail`: Prevent errors in a pipeline (`|`) from being masked
    set -euo pipefail

    if [ ! "{{os()}}" = "linux" ]; then
        echo "ERROR: The operating system {{os()}} is not supported yet."
        exit 1
    fi

    if [ ! "{{linux_distro}}" = "fedora" ]; then
        echo "ERROR: The Linux distribution {{linux_distro}} is not supported yet."
        exit 1
    fi

    echo "Installing base dependencies on {{linux_distro}} (see sys/unix/NewInstall.unx and sys/unix/README-hints)"
    # Base dependencies, which supports tty mode (terminal/ASCII)
    sudo dnf install gcc gdb flex bison

    # ncurses (curses) mode
    sudo dnf install ncurses-devel

    # X11 mode
    sudo dnf install libX11-devel motif-devel libXaw-devel

    # Qt6 mode (do not use Qt5 if you use this)
    sudo dnf install qt6-qtbase-devel qt6-qtmultimedia-devel

    # Qt5 mode (do not use Qt6 if you use this)
    sudo dnf install qt5-qtbase-devel qt5-qtmultimedia-devel
    # HACK: Workaround because, on Fedora 43, the `moc` binary from
    # qt5-qtbase-devel is stored at `/usr/bin/moc-qt5`, which the build cannot
    # find because it is looking for `/usr/bin/moc`.
    # Alternatively, we could modify the respective "hints" file to set
    # MOC (or MOCPATH?) appropriately, as described at
    # https://nethackwiki.com/wiki/Qt#Linux
    #if [ ! -e "/usr/bin/moc" ]; then
    #    if [ -f "/usr/bin/moc-qt5" ]; then
    #        sudo ln -s /usr/bin/moc-qt5 /usr/bin/moc
    #    fi
    #fi

# alias for 'build-linux'
[group('development')]
build: build-linux

# build Linux app
[group('development')]
build-linux:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "== Building NetHack (Linux) for the local user =="
    (cd sys/unix && ./setup.sh hints/linux.370.miguno) || exit 1
    make fetch-lua && make WANT_WIN_ALL=1 WANT_WIN_QT6=1 all || exit 1
    echo "== Build of NetHack (Linux) completed =="

# alias for 'install-linux'
[group('development')]
install: install-linux

# build and install the Linux app including system-wide manpages
[group('development')]
install-linux: install-dependencies install-linux-app install-linux-manpages

# install the Linux app
[group('development')]
install-linux-app: build-linux
    #!/usr/bin/env bash
    set -euo pipefail
    echo "== Installing NetHack (Linux) for the local user =="
    make WANT_WIN_ALL=1 WANT_WIN_QT6=1 install || exit 1
    echo
    echo "== Installation of NetHack (Linux) completed =="

# build and install the Linux manpages system-wide (requires sudo)
[group('development')]
install-linux-manpages:
    sudo make manpages

# alias for 'run-linux'
[group('development')]
run: run-linux

# run the Linux app
[group('app')]
run-linux:
    #!/usr/bin/env bash
    $HOME/nethack/nethack
