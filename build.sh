#!/bin/sh -e
if [ -e build ]; then
    rm -rf build;
fi
cmake . -Bbuild -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++
cmake --build build --

