
IRAP_VERSION=0.6.0

# Create a docker container
iRAP.docker.tar.gz: ../Makefile iRAP.docker
	IMAGE=`cat iRAP.docker| sudo docker build --rm --tag fedora/irap:v$(IRAP_VERSION) -  | grep "Successfully built" | cut -f 3 -d\ ` && \
	docker save $$IMAGE |gzip> $@.tmp && mv $@.tmp $@

iRAP-pcawg.docker.tar.gz: ../Makefile iRAP-pcawg.docker
	IMAGE=`cat iRAP-pcawg.docker| sudo docker build --rm --tag fedora/irap_pcawg:v$(IRAP_VERSION) -  | grep "Successfully built" | cut -f 3 -d\ ` && \
        docker save $$IMAGE |gzip> $@.tmp && mv $@.tmp $@

# run irap
iRAP-devel-pcawg.docker.tar.gz: ../Makefile iRAP-devel-pcawg.docker
	IMAGE=`cat iRAP-devel-pcawg.docker| sudo docker build --rm --tag fedora/irap-pcawg:devel -  | grep "Successfully built" | cut -f 3 -d\ ` && \
	docker save $$IMAGE |gzip> $@.tmp && mv $@.tmp $@

iRAP-devel.docker.tar.gz: ../Makefile iRAP-devel.docker
	IMAGE=`cat iRAP-devel.docker| sudo docker build --rm --tag fedora/irap:devel -  | grep "Successfully built" | cut -f 3 -d\ ` && \
	docker save $$IMAGE |gzip> $@.tmp && mv $@.tmp $@


iRAP-newrel.docker.tar.gz: ../Makefile iRAP-newrel.docker
	IMAGE=`cat iRAP-newrel.docker| sudo docker build --rm --tag fedora/irap:devel -  | grep "Successfully built" | cut -f 3 -d\ ` && \
	docker save $$IMAGE |gzip> $@.tmp && mv $@.tmp $@

iRAP-newrel.docker2.tar.gz: ../Makefile iRAP-newrel2.docker
	IMAGE=`cat iRAP-newrel2.docker| sudo docker build --rm --tag fedora/irap:devel2 -  | grep "Successfully built" | cut -f 3 -d\ ` && \
	docker save $$IMAGE |gzip> $@.tmp && mv $@.tmp $@


install_docker:
	sudo yum -y install docker-io
	sudo groupadd docker
	sudo gpasswd -a `whoami` docker
	sudo service docker restart
	sudo systemctl start docker
	sudo systemctl enable docker


iRAP.docker: irap_docker_template
	cp irap_docker_template $@

docker_files: iRAP-devel.docker iRAP.docker iRAP-devel-pcawg.docker iRAP-pcawg.docker

iRAP-devel.docker: irap_docker_template
	cp irap_docker_template $@.tmp &&\
	sed -i -E 's|RUN ./scripts|RUN git checkout devel \&\& ./scripts|' $@.tmp &&\
	mv $@.tmp $@


iRAP-newrel.docker: irap_docker_template
	cp irap_docker_template $@.tmp &&\
	sed -i -E 's|RUN ./scripts|RUN git checkout irap_new_release  \&\& ./scripts|' $@.tmp &&\
	mv $@.tmp $@


%-pcawg.docker: %.docker
	sed 's|scripts/irap_install.sh|pcawg/irap_install_pcawg.sh|'  $< > $@
