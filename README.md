# mediaserver

Plex + Transmission on a Raspberry Pi 4 (Argon ONE case), with Docker Compose.

| What | Where |
|---|---|
| Transmission (downloads) | http://192.168.68.62:9091 |
| Plex | http://192.168.68.62:32400/web |

## Daily use

1. Download the `.torrent` from your tracker.
2. Open Transmission and drop the file in (or copy it into `watch/`).
   - Movie: nothing to change, it goes to `/downloads/movies`.
   - Series: set the destination to `/downloads/shows` in the add dialog.
3. When it's done, Transmission stops it (no seeding) and it shows up in Plex by itself.

## Commands (run in `~/mediaserver`)

```sh
make status    # temperature, power, disks, containers, torrents
make update    # new Plex/Transmission versions
make logs      # what's happening (Ctrl+C to quit)
make restart
```

## Install / first run

```sh
git clone https://github.com/LucasScellos/mediaserver.git && cd mediaserver
cp .env.example .env    # set the Transmission password
make up
make tune               # one-time: system + Transmission tuning, then `sudo reboot`
```

In Plex: **Settings > Transcoder > Transcoder temporary directory = `/transcode`** (in RAM, spares the SD card).
On the TV/phone apps, set video quality to **Original/Maximum**: the Pi 4 has no hardware transcoding in Plex, so a 4K HEVC file converted on the fly pins the CPU and everything lags.

## Layout

```
DATA_DIR/            (./downloads today, /mnt/media once on a USB disk)
├── movies/          Plex "Films" (/movies)
├── shows/           Plex "Séries TV" (/shows)
└── incomplete/      downloads in progress
```

Transmission downloads straight into `movies/` and `shows/`: one copy of each file, no duplicates.

## Moving the media to a USB disk

Plug the disk into a **blue** (USB 3) port, then:

```sh
lsblk                                   # find it, e.g. sda
sudo mkfs.ext4 -L media /dev/sda1       # ERASES the disk (create a partition first if it has none)
sudo mkdir -p /mnt/media
echo 'LABEL=media /mnt/media ext4 defaults,noatime,nofail 0 2' | sudo tee -a /etc/fstab
sudo mount -a && sudo chown pi:pi /mnt/media

make down
rsync -aH --info=progress2 downloads/ /mnt/media/
sed -i 's|^DATA_DIR=.*|DATA_DIR=/mnt/media|' .env
make up                                 # check Plex and Transmission, then: rm -rf downloads/*
```

Nothing to change in Plex or Transmission: paths inside the containers stay the same.

See [docs/AUDIT-2026-09.md](docs/AUDIT-2026-09.md) for why things are set up this way.
