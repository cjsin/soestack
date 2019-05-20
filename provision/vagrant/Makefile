sync:
	echo syncing...; vagrant rsync; echo done.

syncloop:
	while date ; do echo syncing...; vagrant rsync; echo done.;  read -t 15 -p "hit enter to sync"; done
