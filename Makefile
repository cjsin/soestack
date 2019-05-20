
sync:
	cd provision/vagrant && make sync

syncloop:
	cd provision/vagrant && make syncloop

ks-update:
	cd provision/kickstart && make update

update:	ks-update sync

salt-test:
	salt-call state.highstate --file-root=$PWD/salt --local --retcode-passthrough mocked=True
