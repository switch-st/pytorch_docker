#!/bin/bash

REPO_PYTORCH=https://github.com/pytorch/pytorch.git
REPO_TORCHVISION=https://github.com/pytorch/vision.git
DIR_PYTORCH='pytorch'
DIR_TORCHVISION='torchvision'
PY_VERSION=''
VI_VERSION=''
# pytorch version => vision version
declare -A VER_MAP=(
        ['v1.7.0']='v0.8.0'
        ['v1.6.0']='v0.7.0'
        ['v1.5.1']='v0.6.1'
        ['v1.5.0']='v0.6.0'
        ['v1.4.0']='v0.5.0'
        ['v1.3.1']='v0.4.2'
        ['v1.3.0']='v0.4.1'
        ['v1.2.0']='v0.4.0'
        ['v1.1.0']='v0.3.0'
        ['master']='master'
        ['nightly']='nightly'
    )

function CheckCode() {
    if [ $? -ne 0 ]; then
        echo $1
        exit 100
    fi
}

function LoadGitSource() {
    REPO="$1"
    VERSION="$2"
    DIR="$3"
    COMMIT="$4"
    if [ -z $REPO ] || [ -z $VERSION ] || [ -z $DIR ]; then
        echo parameter error
        return 1
    fi
    echo load `echo $REPO | awk -F'[/.]' '{print $(NF-1)}'` source to $DIR
    if [ ! -d $DIR ]; then
        git clone $REPO $DIR
        CheckCode 'load failed'
    fi
    cd $DIR && git checkout -f master && \
    if [ -n "`git tag -l $VERSION`" ]; then
        git pull &&  git checkout -f $VERSION
    else
        git checkout -f $VERSION && git pull
    fi && \
    if [ -n "$COMMIT" ]; then
        git reset --hard $COMMIT
    fi && cd -
    CheckCode 'load failed'
}

if [ -n "$1" ]; then
    PY_VERSION="$1"
else
    PY_VERSION='master'
    VI_VERSION='master'
fi

if [ -n "$2" ]; then
    PY_GIT_COMMIT="$2"
fi
if [ -n "$3" ]; then
    VI_GIT_COMMIT="$3"
fi

VI_VERSION=${VER_MAP[$PY_VERSION]}
if [ -z $PY_VERSION ] || [ -z $VI_VERSION ]; then
    echo pytorch version or vision version is empty
    exit 1
fi

echo '######################################################'
echo -e \\t init pytorch docker build environment
echo -e \\t pytorch: $PY_VERSION
echo -e \\t vision: $VI_VERSION
echo '######################################################'
echo
LoadGitSource $REPO_PYTORCH $PY_VERSION $DIR_PYTORCH $PY_GIT_COMMIT
echo
echo init pytorch submodules
cd $DIR_PYTORCH && git submodule update --init --recursive -f && cd ..
CheckCode 'init pytorch submodules failed'
echo
LoadGitSource $REPO_TORCHVISION $VI_VERSION $DIR_TORCHVISION $VI_GIT_COMMIT
echo
echo init success
