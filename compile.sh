#!/bin/bash

PREFIX=$HOME/opt/dftb+

FC=gfortran CC=gcc cmake -B _build -DCMAKE_INSTALL_PREFIX=$PREFIX -DBUILD_SHARED_LIBS=ON -DWITH_API=ON -DENABLE_DYNAMIC_LOADING=1
cmake --build _build -j
cmake --install _build
