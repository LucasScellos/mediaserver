.PHONY: up down restart update status logs tune

up:        ## start Plex + Transmission
	docker compose up -d

down:      ## stop everything
	docker compose down

restart:   ## restart everything
	docker compose restart

update:    ## pull new images, restart, clean old images
	docker compose pull
	docker compose up -d
	docker image prune -f

status:    ## temperature, power, disks, containers, torrents
	@./scripts/status.sh

logs:      ## follow logs (Ctrl+C to quit)
	docker compose logs -f --tail=100

tune:      ## one-time system + Transmission tuning
	sudo ./scripts/tune-pi.sh
	./scripts/tune-transmission.sh
