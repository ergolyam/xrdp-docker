# xrdp-docker
This project provides a **tiny image that boots straight into an XRDP + IceWM session** and then immediately runs whatever GUI program you supply.  
Treat it like an appliance you can build on: add your application, copy `/startapp.sh`, and you are done.

> **Why a “base image”?**  
> There are many GUI apps, but only one piece of XRDP plumbing is needed for all of them.  By pulling this image as a parent you keep your own image slim (most of the weight is fonts and XRDP itself) and you can focus on shipping **your** program.

## Create your own image

- Below is the **minimal pattern** you will use over and over:
    ```dockerfile
    FROM ghcr.io/ergolyam/xrdp-docker:latest  # <‑‑ the base image

    RUN apk add --no-cache xterm # pull in the GUI program(s) you need

    COPY startapp.sh /startapp.sh # launcher that XRDP will run

    RUN chmod +x /startapp.sh # permission to run
    ```
    - Example `startapp.sh`:
        ```bash
        #!/usr/bin/env sh
        exec xterm # start your GUI; exit -> session ends
        ```
    - `/startapp.sh` is required and must be executable. If it is missing, the container exits immediately.
    - You can also provide an optional `/entrypoint.sh`; it runs after the RDP user is created and before `xrdp` starts.

- Build & run:
    ```bash
    docker build -t xrdp-xterm .
    docker run -p 3389:3389 \
                -e USER=demo -e PASSWD=secret \
                xrdp-xterm
    ```

- Run with ssl keys:
    ```bash
    openssl req -x509 -newkey rsa:2048 -nodes -keyout /path/to/key.pem -out /path/to/cert.pem -days 365
    ```
    ```bash
    docker run -p 3389:3389 \
                -e USER=demo -e PASSWD=secret \
                -v /path/to/key.pem:/key.pem:ro \
                -v /path/to/cert.pem:/cert.pem:ro \
                xrdp-xterm
    ```

- Connect to **`localhost:3389`** with any RDP client (username **demo**, password **secret**) you will land in a maximised `xterm`.

## Environment Variables

The container is controlled via the following environment variables:

| Variable     | Description |
|--------------|-------------|
| `USER`       | Username for the RDP session. The specified user will be created automatically if it does not already exist. |
| `PASSWD`     | Password for the RDP session user. It is applied on every container start. |
| `TZ`         | (Optional) Time zone for the container (for example `Europe/Moscow`). Applied only when the corresponding zoneinfo file exists. |
| `DARK_MODE`  | (Optional) If set to `true`, exports dark-theme variables for GTK and Qt applications. |
| `PORT`       | (Optional) Port that XRDP will listen on (default is `3389`). Remember to publish the same port with Docker. |
| `DISPLAY`    | (Optional) X display offset used by XRDP/Xorg (default is `10`). Useful when running multiple containers side by side. |
| `LOGOUT_TIMEOUT` | (Optional) Inactivity timeout in minutes before `xautolock` logs the session out. |
| `XKBMAP_LAYOUT` | (Optional) Enables keyboard layout switching between `us` and the specified XKB layout (for example `ru`). |
| `XKBMAP_OPTION` | (Optional) XKB option string used for layout switching (default: `grp:win_space_toggle`). |

## Hooks you can use

* **`/entrypoint.sh`** – Optional. Runs before starting xrdp, after creating a user, suitable for creating base directories and granting permissions to the user.
* **`/startapp.sh`** – Required. It is launched by IceWM after login. It should be executable; when it exits, the session logs out and the container shuts down.

## Features

- **No VNC hop**: uses `xrdp` + `xorgxrdp`; clients see a native RDP server on port 3389.
- **IceWM kiosk mode**: no task‑bar, no start menu your app opens maximised and owns the screen.
- **Environment‑driven**: just supply `USER`, `PASSWD`, `/startapp.sh`.
- **Optional keyboard layout switcher**: set `XKBMAP_LAYOUT=ru` to toggle between `us` and `ru`.

## Published tags

The GitHub workflow currently publishes these tags:

- `latest` (alias for `alpine-latest`)
- `alpine-3.19`, `alpine-3.20`, `alpine-3.21`, `alpine-3.22`, `alpine-latest`, `alpine-edge`
- `debian-12-slim`, `debian-13-slim`

## Projects Using This Image

Here are some example projects built on top of `xrdp-docker`:

- [**xrdp-firefox**](https://github.com/ergolyam/xrdp-firefox) – A minimal container that launches Firefox in a remote desktop session via XRDP.

> Have you built something with `xrdp-docker`? Feel free to open a PR and add your project here!

## License

This program is free software: you can redistribute it and/or modify it under the terms of the **GNU General Public License, version 3 or (at your option) any later version** published by the Free Software Foundation.

Copyright © 2025 ergolyam

See the full license text in the [LICENSE](license) file or online at <https://www.gnu.org/licenses/gpl-3.0.txt>.
