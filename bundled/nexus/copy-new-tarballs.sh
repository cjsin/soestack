#!/bin/sh
set -e
mkdir -p prior

if ls | egrep '[.]tar$' 
then
	  mv -i *.tar prior/
fi

host=192.168.121.101
datadir="/d/local/data/nexus"

set -vx
ssh-copy-id -i ~/.ssh/id_rsa "root@${host}"

ssh "root@${host}" "cd '${datadir}/backups' && tar cf - *.bak" > db-backup.tar
tar tvf db-backup.tar

ssh "root@${host}" "cd '${datadir}' && tar --checkpoint=20000 -cf - blobs/" > blobs.tar
tar tvf blobs.tar | head -n1 


