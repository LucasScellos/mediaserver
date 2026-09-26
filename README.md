# mediaserver

My home media server: a Raspberry Pi 4 that downloads movies and series (Transmission)
and plays them on the TV (Plex).

| | Address |
|---|---|
| **Add a download** | http://192.168.68.62:9091 |
| **Watch** | Plex app on the TV / phone, or http://192.168.68.62:32400/web |

## Add a movie or a series

1. Download the `.torrent` file from the tracker.
2. Open http://192.168.68.62:9091 and log in.
3. Click the **folder icon** (top left) and pick the `.torrent` file.
4. **Destination folder**:
   - movie: leave `/downloads/movies`
   - series: type `/downloads/shows`
5. Click **Upload**.

When the download is finished it stops by itself and appears in Plex (**Films** or **Séries TV**).

## How it behaves (on purpose)

- **No seeding.** A torrent stops as soon as it is complete.
- **No video conversion.** The Pi 4 is too weak to convert video, so Plex only plays files the
  player can read as they are. If a video refuses to play:
  - get a **1080p x264 / x265** version instead of 4K / Dolby Vision,
  - use **SRT** subtitles or none (PGS/ASS image subtitles would need a conversion),
  - on the player: Settings → Quality → **Original / Maximum**, "adjust quality automatically" off.
- **The fan** (Argon ONE case) starts on its own above 55 °C.

## Commands

On the Pi (`ssh pi@192.168.68.62`), in `~/mediaserver`:

| Command | What it does |
|---|---|
| `make status` | temperature, power, free space, containers, torrents |
| `make update` | install new Plex / Transmission versions |
| `make restart` | restart Plex and Transmission |
| `make logs` | show what's happening (Ctrl+C to quit) |

## Install from scratch

```sh
git clone https://github.com/LucasScellos/mediaserver.git && cd mediaserver
cp .env.example .env     # choose the Transmission login
make up                  # then open http://<pi-ip>:32400/web and sign in to Plex
make tune                # system, Transmission and Plex settings
make fan                 # Argon ONE fan service
sudo reboot
```

In Plex, create two libraries: **Films** → `/movies`, **Séries TV** → `/shows`.

## Folders

```
~/mediaserver/
├── .env                 login + where the media lives (DATA_DIR), not in git
├── config/              Plex and Transmission settings/databases, not in git
├── downloads/           = DATA_DIR
│   ├── movies/          → Plex "Films"
│   ├── shows/           → Plex "Séries TV"
│   └── incomplete/      downloads in progress
├── watch/               a .torrent copied here starts downloading by itself
└── scripts/             tuning, status, fan install
```

## Moving the media to a USB disk (optional)

Only needed if the library outgrows the SD card. Plug the disk into a **blue** USB 3 port:

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

Nothing to change in Plex or Transmission: the paths inside the containers stay the same.

---

Hardware, design choices and rules for AI agents: [AGENTS.md](AGENTS.md).
History of the September 2026 audit: [docs/AUDIT-2026-09.md](docs/AUDIT-2026-09.md).
