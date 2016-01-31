#!/usr/bin/env bash
pushd $(dirname $0) > /dev/null; CURRABSPATH=$(readlink -nf "$(pwd)"); popd > /dev/null; # Get the directory in which the script resides

set -x

MUSLPKG="musl:musl.tgz:http://www.musl-libc.org/releases/musl-${MUSL_VERSION}.tar.gz"
LEVTPKG="libevent:libevent2.tgz:https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}-stable/libevent-${LIBEVENT_VERSION}-stable.tar.gz"
TMUXPKG="tmux:tmux.tgz:https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz"
NCRSPKG="ncurses:ncurses.tgz:http://ftp.gnu.org/pub/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz"
TEMPDIR="$CURRABSPATH/tmp"
TMPLIB="tempinstall/lib"
TMPINC="tempinstall/include"
MUSLCC="$TEMPDIR/musl/tempinstall/bin/musl-gcc"

[[ -d "$TEMPDIR" ]] || mkdir "$TEMPDIR" || { echo "FATAL: Could not create $TEMPDIR."; exit 1; }

for i in "$MUSLPKG" "$NCRSPKG" "$LEVTPKG" "$TMUXPKG"; do
    NAME=${i%%:*}
    i=${i#*:}
    TGZ=${i%%:*}
    URL=${i#*:}
    [[ -d "$TEMPDIR/$NAME" ]] && rm -rf "$TEMPDIR/$NAME"
    [[ -d "$TEMPDIR/$NAME" ]] || mkdir  "$TEMPDIR/$NAME" || { echo "FATAL: Could not create $TEMPDIR/$NAME."; exit 1; }
    [[ -f "$CURRABSPATH/$TGZ" ]] || curl -sSL -o "$CURRABSPATH/$TGZ" "$URL" || wget -O "$CURRABSPATH/$TGZ" "$URL" || { echo "FATAL: failed to fetch $URL."; exit 1; }
    echo "Unpacking $NAME" && tar --strip-components=1 -C "$TEMPDIR/$NAME" -xf "$TGZ" && mkdir "$TEMPDIR/$NAME/tempinstall" \
        || { echo "FATAL: Could not unpack one of the required source packages. Check above output for clues."; exit 1; }
    echo "Building $NAME (this may take some time)"
    (
    PREFIX="$TEMPDIR/$NAME/tempinstall"
    case $NAME in
        musl )
            (cd "$TEMPDIR/$NAME" && ./configure --enable-gcc-wrapper --prefix="$PREFIX") && \
                make -C "$TEMPDIR/$NAME" && make -C "$TEMPDIR/$NAME" install
            curl -sSL -o "$TEMPDIR/$NAME/tempinstall/include/sys/queue.h" "http://git.alpinelinux.org/cgit/aports/plain/main/libc-dev/sys-queue.h?id=e3725c0af137717d6883265a92db3838900b5cee"
            curl -sSL -o "$TEMPDIR/$NAME/tempinstall/include/sys/cdefs.h" "http://git.alpinelinux.org/cgit/aports/plain/main/libc-dev/sys-cdefs.h?id=e3725c0af137717d6883265a92db3838900b5cee"
            curl -sSL -o "$TEMPDIR/$NAME/tempinstall/include/sys/tree.h" "http://git.alpinelinux.org/cgit/aports/plain/main/libc-dev/sys-tree.h?id=e3725c0af137717d6883265a92db3838900b5cee"
            ;;
        ncurses )
            (cd "$TEMPDIR/$NAME" && ./configure --without-ada --without-cxx --without-progs --without-manpages --disable-db-install --without-tests --with-default-terminfo-dir=/usr/share/terminfo --with-terminfo-dirs="/etc/terminfo:/lib/terminfo:/usr/share/terminfo" --prefix="$PREFIX" CC="$MUSLCC") && \
                make -C "$TEMPDIR/$NAME" && make -C "$TEMPDIR/$NAME" install
            ;;
        libevent )
            (cd "$TEMPDIR/$NAME" && ./configure --enable-static --enable-shared --disable-openssl --prefix="$PREFIX" CC="$MUSLCC") && \
                make -C "$TEMPDIR/$NAME" && make -C "$TEMPDIR/$NAME" install
            ;;
        tmux )
            (cd "$TEMPDIR/$NAME" && ./configure --enable-static --prefix="$PREFIX" CC="$MUSLCC" CPPFLAGS="-I$TEMPDIR/libevent/$TMPINC -I$TEMPDIR/ncurses/$TMPINC -I$TEMPDIR/ncurses/$TMPINC/ncurses" LDFLAGS="-L$TEMPDIR/libevent/$TMPLIB -L$TEMPDIR/ncurses/$TMPLIB" LIBS=-lncurses) && \
                make -C "$TEMPDIR/$NAME" && make -C "$TEMPDIR/$NAME" install
            strip $PREFIX/bin/tmux
            ;;
    esac
    ) 2>&1 |tee "$TEMPDIR/${NAME}.log" > /dev/null || { echo "FATAL: failed to build $NAME. Consult $TEMPDIR/${NAME}.log for details."; exit 1; }
    unset CC
done
