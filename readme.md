# xrdp-docker
This project provides a **tiny Alpine Linux image that boots straight into an XRDP + IceWM session** and then immediately runs whatever GUI program you supply.  
Treat it like an _appliance_ you can build on—add your application and you are done.

> **Why a “base image”?**  
> There are many GUI apps, but only one piece of XRDP plumbing is needed for all of them.  By pulling this image as a parent you keep your own image slim (most of the weight is fonts and XRDP itself) and you can focus on shipping **your** program.

## Create your own image

- Below is the **minimal pattern** you will use over and over:
    ```dockerfile
    FROM ghcr.io/grisha765/xrdp-docker:latest  # <‑‑ the base image

    RUN apk add --no-cache xterm # pull in the GUI program(s) you need

    RUN chmod +x /startapp.sh # permission to run

    COPY startapp.sh /startapp.sh # launcher that XRDP will run
    ```
    - Example `startapp.sh`:
        ```bash
        #!/usr/bin/env ash
        exec xterm # start your GUI; exit → session ends
        ```

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
                -v /path/to/key.pem:/key.pem:O \
                -v /path/to/cert.pem:/cert.pem:O \
                xrdp-xterm
    ```

- Other working env's:
    ```env
    USER="username"
    PASSWD="password"
    TZ="Europe/Moscow"
    DARK_MODE=true
    ```

- Connect with any RDP client (username **demo**, password **secret**) you will land in a maximised `xterm`.

## Hooks you can use

* **`/entrypoint.sh`** – Runs before starting xrdp, after creating a user, suitable for creating base directories and granting permissions to the user.
* **`/startapp.sh`** – Rust exist; it is launched by IceWM after login. When it exits, the session logs out and the container shuts down.

## Features

- **No VNC hop**: uses `xrdp` + `xorgxrdp`; clients see a native RDP server on port 3389.
- **IceWM kiosk mode**: no task‑bar, no start menu—your app is full‑screen.
- **Environment‑driven**: just supply `USER`, `PASSWD`, `/startapp.sh`.
