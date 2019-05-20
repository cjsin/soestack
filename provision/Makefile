check-scripts:
	find . -name "*.sh" | while read n ; do bash -n "$${n}"; done

sync:
	cd vagrant && make sync

syncloop:
	cd vagrant && make syncloop
