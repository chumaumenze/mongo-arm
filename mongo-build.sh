#!/usr/bin/env bash

TARGET_VERSION="${TARGET_VERSION:-6.2.0}"
TARGET_ARM="${TARGET_ARM:-arm64}"

build-mongosrc() {    
    git clone --depth=1 -b "r${TARGET_VERSION}" https://github.com/mongodb/mongo.git

    case "$TARGET_ARM" in 
        arm | armv5 | armhf | armv7 | armv7l | arm64 | aarch64)
            arch="$TARGET_ARM"
        ;;

        *)
            default="arm64"
            printf "Using default arch $default instead of ${TARGET_ARM:-undefined}"
            arch="$default"
        ;;
    esac


    docker run --rm -v $(pwd)/mongo:/workdir \
        -e CROSS_TRIPLE=aarch64-linux-gnu \
        chumaumenze/crossbuild bash -c "
        printf 'Install additional build dependencies...\n'
        apt-get install -y python-dev-is-python3 python3-pip \
            libssl-dev:$arch libcurl4-openssl-dev:$arch liblzma-dev:$arch
        
        printf 'Install python prerequisites...\n'
        python3 -m pip install -r etc/pip/compile-requirements.txt

        printf 'Compiling...\n'
        python3 buildscripts/scons.py install-mongod \
            MONGO_VERSION=${TARGET_VERSION} \
            CC=/usr/bin/aarch64-linux-gnu-gcc-10 \
            CXX=/usr/bin/aarch64-linux-gnu-g++-10 \
            CCFLAGS='-march=armv8-a+crc -mtune=cortex-a72' \
            --ssl --install-mode=hygienic --install-action=hardlink \
            --disable-warnings-as-errors --separate-debug archive-core{,-debug}
        
        printf 'Stripping compiled binary...\n'
        ls -aslh ./build/install/*/*
        /usr/bin/aarch64-linux-gnu-strip ./build/install/bin/mongod
        "

}
