#!/bin/bash

if [ "$1" != "-f" ];
  then echo not forcing
  exit 1
fi

rm -rf netmap pkg src
