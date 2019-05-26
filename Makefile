
sync:
	cd provision/vagrant && make sync

syncloop:
	cd provision/vagrant && make syncloop

ks-update:
	cd provision/kickstart && make update

update:	ks-update sync

salt-test:
	salt-call state.highstate --file-root=$PWD/salt --local --retcode-passthrough mocked=True

bundled-server:
	(cd bundled && python -m http.server 9999 )&

ssh:
	(cd provision/vagrant; vagrant ssh )

