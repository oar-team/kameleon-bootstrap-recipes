#!/usr/bin/env bash

ROOT_PROJECT=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
BUILD_PATH=$ROOT_PROJECT/build
ROOTFS_PATH=$ROOT_PROJECT/rootfs

trap ctrl_c INT

function ctrl_c() {
        echo "** Trapped CTRL-C"
        echo "** Exited"
        exit 1
}


for RECIPE_PATH in `ls qemu/*.yaml`; do
    RECIPE_NAME=$(basename $RECIPE_PATH .yaml)
    if [ ! -e "$ROOTFS_PATH/${RECIPE_NAME}.tar.xz" ]; then
        rm -rf $BUILD_PATH

        (set -x; kameleon build $ROOT_PROJECT/$RECIPE_PATH --build-path $BUILD_PATH --script --cache-archive-compression=xz --enable-cache)
        if [ $? -eq 0 ]; then
            mkdir -p $ROOTFS_PATH
            mv $BUILD_PATH/$RECIPE_NAME/*.tar.xz $ROOTFS_PATH/
        fi
    fi
done
