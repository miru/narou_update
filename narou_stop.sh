#!/bin/bash

cd ~/narou

for NID in $*
do
    narou.rb tag -d "kindle 未転送 未読" $NID
    narou.rb tag -a "切" $NID
done

cd -

# EOF
