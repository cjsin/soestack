#!/bin/sh
set -e
mkdir -p prior

if ls | egrep '[.]tar$' 
then
    mv -i *.tar prior/
fi

host=192.168.121.101
datadir="/d/local/data/ss-nexus-mirror"

set -vx
ssh-copy-id -i ~/.ssh/id_rsa "root@${host}"

datestring=$(ssh "root@${host}" "cd '${datadir}/backups' && ls -tr config* | tail -n1 |cut -c 8-36")

ssh "root@${host}" "cd '${datadir}/backups' && tar cf - *-${datestring}*.bak" > db-backup.tar
tar tvf db-backup.tar
numfiles=$(tar tvf db-backup.tar | egrep '[.]bak' | wc -l)
if [[ "${numfiles}" -gt 4 ]]
then
   echo "ERROR: db-backup has too many files! You need to delete earlier backups!" 1>&2
   exit 1
fi 


ssh "root@${host}" "cd '${datadir}' && tar --checkpoint=20000 -cf - blobs/" > blobs.tar
tar tvf blobs.tar | head -n1 

