#!/bin/bash
# -*- coding:utf-8 -*-

# Get Settings
. `dirname $0`/narou_update.settings

# Load function
. `dirname $0`/narou_update_func.sh

# run check
wait_other_script

### main ###
pushd $NAROU_DIR

if [ -f "./download.txt" -a -s "./download.txt" ]; then
    mv -f ./download.txt ./download.txt.tmp
    touch ./download.txt
    URLS=`cat ./download.txt.tmp`
    $NAROU d -n $URLS
    $NAROU tag -a "NEW" $URLS

    G=`echo "$URLS" | perl -ne 'BEGIN{@F=()} {chomp(); push(@F,$_)}; END{print "(" . join("|",@F) . ")"}'`

    if [ "$NOTIFY_TYPE" == "SLACK" ]; then
        TITLE=`$NAROU list -u -e | egrep -e $G | grep -v タイトル | \
        perl -F'\|' -alne 'print ":id:" . $F[0] . ":inbox_tray:" . $F[2]' | \
        perl -pe 's/\(完結\)/:white_flower:/g' | \
        perl -pe 'BEGIN{use encoding utf8;} s/(～|「).*(～|」)//g' | \
        perl -pe 'BEGIN{use encoding utf8;} s/(^:id:[^(、|。)]+)(、|。).*(:white_flower:)?/\1\2/g' `
        send_notification ":inbox_tray:小説ダウンロード" "$TITLE"
    else
        TITLE=`$NAROU list -u -e | egrep -e $G | grep -v タイトル | \
        perl -F'\|' -alne 'print "ID:" . $F[0] . "■" . $F[2]'
        perl -pe 'BEGIN{use encoding utf8;} s/(～|「).*(～|」)//g' | \
        perl -pe 'BEGIN{use encoding utf8;} s/(^:id:[^(、|。)]+)(、|。).*(\(完結\)?/\1\2/g' `
        send_notification "【小説DL】" "$TITLE"
    fi
fi

popd

exit
# EOF
