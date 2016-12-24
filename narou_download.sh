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
    DT=`date +%Y%m%d_%H%M%S`
    mv -f ./download.txt $DOWN_HISTORY/download.$DT.txt
    touch ./download.txt
    URLS=`egrep -v "(^$|^#)" $DOWN_HISTORY/download.$DT.txt`
    $NAROU d -n $URLS
    $NAROU tag -a "NEW" $URLS

    G=`echo "$URLS" | perl -pe 's/\r//g' | perl -ne 'BEGIN{@F=()} {chomp(); push(@F,$_)}; END{print "(" . join("|",@F) . ")"}'`

    if [ "$NOTIFY_TYPE" == "SLACK" ]; then
        TITLE=`$NAROU list -u -e | egrep -e $G | grep -v タイトル | \
        perl -F'\|' -alne 'print ":id:" . $F[0] . ":inbox_tray:" . $F[2]' | \
        perl -pe 'BEGIN{use utf8;use Encode;} s/(^:id:[^(、|、|。)]+)(、|、|。).*\(完結\)/\1... :white_flower:/g' | \
        perl -pe 'BEGIN{use utf8;use Encode;} s/\(完結\)/\:white_flower:/g' | \
        perl -pe 'BEGIN{use utf8;use Encode;} s/(^:id:[^(、|、|。)]+)(、|、|。).*/\1/g' | \
        perl -pe 'BEGIN{use utf8;use Encode;} s/(^ [^(～|ー|「|\-|（)].*)(～|ー|「|\-|（).*(～|ー|」|\-|）)/\1/g' `
        send_notification ":inbox_tray:小説ダウンロード" "$TITLE"
    else
        TITLE=`$NAROU list -u -e | egrep -e $G | grep -v タイトル | \
        perl -F'\|' -alne 'print "ID:" . $F[0] . "■" . $F[2]'
        perl -pe 'BEGIN{use utf8;use Encode;} s/(～|～|「|\-|（).*(～|～|」|\-|）)//g' | \
        perl -pe 'BEGIN{use utf8;use Encode;} s/(^ID:[^(、|、|。)]+)(、|、|。).*(\(完結\))?/\1\3/g' `
        send_notification "【小説DL】" "$TITLE"
    fi
fi

$NAROU freeze --on `$NAROU list -t 404 | cat`

popd

exit
# EOF
