#!/bin/bash

cd ~/narou

for NID in $*
do
    narou.rb tag -a "購読中" $NID
    narou.rb tag -d "変換済み 未読 kindle 未転送" $NID
done

cd -

# EOF
