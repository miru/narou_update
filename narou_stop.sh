#!/bin/bash

cd ~/narou

for NID in $*
do
    narou.rb tag -d "kindle 購読中 購読中な 未変換 未転送 変換済み 未読" $NID
    narou.rb tag -a "切" $NID
done

cd -

# EOF
