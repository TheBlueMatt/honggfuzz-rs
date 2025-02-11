#!/bin/sh -ve
export RUST_BACKTRACE=full

git submodule update --init

cargo uninstall honggfuzz 2>/dev/null || true
cargo clean
cargo update

# install cargo subcommands, unsetting the arbitrary feature for 1.47
version=`rustc --version`
if [ -n "${version##*1.47*}" ] ;then
	cargo install --path . --force --verbose
else
	cargo install --path . --force --verbose --no-default-features
fi
cargo hfuzz version

cd example

if [ -n "${version##*1.47*}" ] ;then
	# run test.sh without sanitizers with the `arbitrary` crate
	HFUZZ_BUILD_ARGS="--features arbitrary" ./test.sh
fi

# run test.sh without sanitizers without the `arbitrary` crate
HFUZZ_BUILD_ARGS="--no-default-features" RUSTFLAGS="" ./test.sh

# run test.sh with sanitizers only on nightly
if [ -z "${version##*nightly*}" ] ;then
	if [ "`uname`" = "Linux" ] ;then
		RUSTFLAGS="-Z sanitizer=address" ./test.sh # not working on macos
		RUSTFLAGS="-Z sanitizer=thread" ./test.sh # not working on macos
		RUSTFLAGS="-Z sanitizer=leak" ./test.sh # the leak sanitizer is only available on Linux
	fi
	# RUSTFLAGS="-Z sanitizer=memory" ./test.sh # not working, see: https://github.com/rust-lang/rust/issues/39610
fi

# go back to root crate
cd ..

if [ -n "${version##*1.47*}" ] ;then
	# try to generate doc
	cargo doc

	# run unit tests
	cargo test
else
	cargo doc --no-default-features

	# run unit tests
	cargo test --no-default-features
fi

cargo clean
