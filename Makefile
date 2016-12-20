TAGFIX := blockchain-mail-

create:
	docker build --tag=$(TAGFIX)devel devel
	docker build --tag=$(TAGFIX)exec exec
