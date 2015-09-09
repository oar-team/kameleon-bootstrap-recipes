#!/usr/bin/env bash

ROOT_PROJECT=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
BUILD_PATH=$ROOT_PROJECT/build
ROOTFS_PATH=$ROOT_PROJECT/rootfs


for RECIPE_PATH in `ls qemu/*.yaml`; do
    if [ ! -e "$ROOTFS_PATH/${RECIPE_NAME}.tar.xz" ]; then
        rm -rf $BUILD_PATH

        RECIPE_NAME=$(basename $RECIPE_PATH .yaml)

        kameleon build $ROOT_PROJECT/$RECIPE_PATH --build-path $BUILD_PATH --script

        if [ $? -eq 0 ]; then
            mkdir -p $ROOTFS_PATH
            mv $BUILD_PATH/$RECIPE_NAME/*.tar.xz $ROOTFS_PATH/
        fi
    fi
done
