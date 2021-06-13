SRC='/data'
DEST='deng@192.168.38.132::backup'
inotifywait -mrq --timefmt '%Y-%m-$d %H:%M' --format '%T %w %f' -e create,delete,moved_to,close_write,attrib ${SRC} | while read DATA TIME DIR FILE;do
        FILEPATH=${DIR}${FILE}
        rsync -az --delete --password-file=/etc/rsync.pass $SRC $DEST && echo "At ${TIME} on ${DATA},file ${FILE} was backup via rsync" >> /var/log/changelist.log                                                              
done

