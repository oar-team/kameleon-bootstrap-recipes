#!/bin/bash

set -e

export http_proxy=
export https_proxy="$http_proxy"
export ftp_proxy="$http_proxy"
export rsync_proxy="$http_proxy"
export all_proxy="$http_proxy"
export HTTP_PROXY="$http_proxy"
export HTTPS_PROXY="$http_proxy"
export FTP_PROXY="$http_proxy"
export RSYNC_PROXY="$http_proxy"
export ALL_PROXY="$http_proxy"
export no_proxy="localhost,$(echo $http_proxy | tr ":" "\n" | head -n 1),127.0.0.1,localaddress,.localdomain"
export NO_PROXY="$no_proxy"
export PATH=/usr/bin:/usr/sbin:/bin:/sbin:$PATH

cd /tmp/
curl -L https://api.github.com/repos/p8952/genstall/tarball > genstall.tar.gz
tar xvf genstall.tar.gz
cd p8952-genstall-*
bash install.sh

# force reboot
systemctl reboot
