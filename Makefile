TAGFIX := blockchain-mail-
V := /task/Bitse
W := $V/blockchain-mail
SOURCE := $W/source

build: start-development $(SOURCE)/Makefile
	docker exec $(TAGFIX)devel make -C $(SOURCE)

config: $(SOURCE)/Makefile ; test $(SOURCE)/Makefile
$(SOURCE)/Makefile: $W/docker/dock.mk
	docker exec $(TAGFIX)devel make -f docker/dock.mk W=$W configure

create:
	docker build --tag=$(TAGFIX)devel devel
	docker build --tag=$(TAGFIX)exec exec

start-development:
	@docker rm $$(docker ps -a | grep '\(Exited\|Created\)' | grep '$(TAGFIX)devel' | awk '{ print $$1 }') 1>/dev/null 2>/dev/null || true
	@docker ps | grep $(TAGFIX)devel > /dev/null || \
	  docker run -d -t \
	    -v "$V:$V" \
	    -w "$W" \
	    --name $(TAGFIX)devel \
	    $(TAGFIX)devel \
	  bash -i
