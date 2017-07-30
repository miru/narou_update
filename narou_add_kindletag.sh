#!/bin/bash

cd ~/narou

#for NID in $*
#do
#    narou.rb tag -a "kindle 未転送" $NID
#    narou.rb tag -d "変換済み 未読 次" $NID
#    narou.rb convert $NID
#done

narou.rb tag -a "kindle 未転送" $*
narou.rb tag -d "変換済み 未読 次" $*
narou.rb convert $*

cd -

# EOF
