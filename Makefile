SPHINXBUILD   = sphinx-build

.PHONY: venv sync syncloop us-update update salt-test bundled-server ssh venv html \
	ss-centos-base podman docker buildah 
	
sync:
	cd provision/vagrant && make sync

syncloop:
	cd provision/vagrant && make syncloop

ks-update:
	cd provision/kickstart && make update

update:	ks-update sync

salt-test:
	salt-call state.highstate --file-root=$(PWD)/salt --local --retcode-passthrough mocked=True

bundled-server:
	(cd bundled && python -m http.server 9999 )&

ssh:
	(cd provision/vagrant; vagrant ssh )

venv:
	test -d venv || python3 -m venv venv 
	. venv/bin/activate && ( pip install --upgrade pip && pip list | egrep sphinx || pip install sphinx  )
	
sphinx-help: venv
	. venv/bin/activate && @$(SPHINXBUILD) -M help docs public $(O)

htdocs: venv docs/*.rst
	. venv/bin/activate && $(SPHINXBUILD) docs htdocs

gitlab-pages: venv docs/*.rst
	. venv/bin/activate && $(SPHINXBUILD) docs public

github-pages: venv docs/*.rst
	. venv/bin/activate && $(SPHINXBUILD) docs ../soestack-github-pages/

ss-centos-base:
	buildah bud --layers -t ss-centos-base:latest -f Dockerfile.base . 

docker:
	docker build .

podman:
	podman build .

buildah:
	buildah bud --layers -f Dockerfile .

