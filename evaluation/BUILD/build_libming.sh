#!/bin/bash

# For Mac
if [ $(command uname) = "Darwin" ]; then
    if ! [ -x "$(command -v greadlink)"  ]; then
        brew install coreutils
    fi
    BIN_PATH=$(greadlink -f "$0")
    ROOT_DIR=$(dirname $(dirname $(dirname $BIN_PATH)))
# For Linux
else
    BIN_PATH=$(readlink -f "$0")
    ROOT_DIR=$(dirname $(dirname $(dirname $BIN_PATH)))
fi

if ! [ -d "${ROOT_DIR}/tool/MemLock/build/bin" ]; then
	${ROOT_DIR}/tool/install_MemLock.sh
fi

if ! [ -d "${ROOT_DIR}/tool/AFL-2.52b/build/bin" ]; then
	${ROOT_DIR}/tool/install_MemLock.sh
fi

PATH_SAVE=$PATH
LD_SAVE=$LD_LIBRARY_PATH

export PATH=${ROOT_DIR}/clang+llvm/ua_asan/bin:$PATH
export LD_LIBRARY_PATH=${ROOT_DIR}/clang+llvm/ua_asan/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

if ! [ $(command llvm-config --version) = "6.0.1" ]; then
	echo ""
	echo "You can simply run tool/build_MemLock.sh to build the environment."
	echo ""
	echo "Please set:"
	echo "export PATH=$PREFIX/clang+llvm/bin:\$PATH"
	echo "export LD_LIBRARY_PATH=$PREFIX/clang+llvm/lib:\$LD_LIBRARY_PATH"
elif ! [ -d "${ROOT_DIR}/clang+llvm/ua_asan/bin"  ]; then
	echo ""
	echo "You can simply run tool/build_MemLock.sh to build the environment."
	echo ""
	echo "Please set:"
	echo "export PATH=$PREFIX/clang+llvm/ua_asan/bin:\$PATH"
	echo "export LD_LIBRARY_PATH=$PREFIX/clang+llvm/ua_asan/lib:\$LD_LIBRARY_PATH"
else
	echo "start ..."
    cd ${ROOT_DIR}/evaluation/BUILD/libming
    git clone https://github.com/libming/libming SRC
    cd SRC
    git checkout b72cc2fda0e8b3792b7b3f7361fc3f917f269433
    cd ..
    rm -rf $(dirname ${BIN_PATH})/libming/SRC_MemLock
    rm -rf $(dirname ${BIN_PATH})/libming/SRC_AFL
    mv $(dirname ${BIN_PATH})/libming/SRC $(dirname ${BIN_PATH})/libming/SRC_MemLock
    cp -rf $(dirname ${BIN_PATH})/libming/SRC_MemLock $(dirname ${BIN_PATH})/libming/SRC_AFL

	#build MemLock project
	export AFL_PATH=${ROOT_DIR}/tool/MemLock
	export ASAN_OPTIONS=detect_odr_violation=0:allocator_may_return_null=0:abort_on_error=1:symbolize=0:detect_leaks=0
	cd $(dirname ${BIN_PATH})/libming/SRC_MemLock
	make distclean
    ./autogen.sh
	if [ -d "$(dirname ${BIN_PATH})/libming/SRC_MemLock/build"  ]; then
		rm -rf $(dirname ${BIN_PATH})/libming/SRC_MemLock/build
	fi
	mkdir $(dirname ${BIN_PATH})/libming/SRC_MemLock/build
	CC=${ROOT_DIR}/tool/MemLock/build/bin/memlock-heap-clang CXX=${ROOT_DIR}/tool/MemLock/build/bin/memlock-heap-clang++ CFLAGS="-g -O0 -fsanitize=address" CXXFLAGS="-g -O0 -fsanitize=address" ./configure --prefix=$(dirname ${BIN_PATH})/libming/SRC_MemLock/build --disable-shared
	make
	make install

	#build AFL project
	export AFL_PATH=${ROOT_DIR}/tool/AFL-2.52b
	export ASAN_OPTIONS=detect_odr_violation=0:allocator_may_return_null=0:abort_on_error=1:symbolize=0:detect_leaks=0
	cd $(dirname ${BIN_PATH})/libming/SRC_AFL
	make distclean
    ./autogen.sh
	if [ -d "$(dirname ${BIN_PATH})/libming/SRC_AFL/build"  ]; then
        rm -rf $(dirname ${BIN_PATH})/libming/SRC_AFL/build
    fi
    mkdir $(dirname ${BIN_PATH})/libming/SRC_AFL/build
    CC=${ROOT_DIR}/tool/AFL-2.52b/build/bin/afl-clang-fast CXX=${ROOT_DIR}/tool/AFL-2.52b/build/bin/afl-clang-fast++ CFLAGS="-g -O0 -fsanitize=address" CXXFLAGS="-g -O0 -fsanitize=address" ./configure --prefix=$(dirname ${BIN_PATH})/libming/SRC_AFL/build --disable-shared
	make
	make install

	export PATH=${PATH_SAVE}
	export LD_LIBRARY_PATH=${LD_SAVE}
fi
