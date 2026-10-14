# Nginx backend lab

This is a small local setup I worked on before the AWS deployment. I kept a page behind Nginx and wrote a Bash loop to check whether the backend could be reached.

The files came from my WSL setup. This lab is separate from the Flask application and Terraform deployment in the main project.

## Request flow

```text
Browser -> Nginx on port 80 -> local server on port 9090 -> index.html
```

- [index.html](index.html) is the small page served by the backend.
- [nginx.conf.example](nginx.conf.example) forwards requests to `127.0.0.1:9090` and passes the original host and client address headers.
- [watchdog.sh](watchdog.sh) calls the backend with curl every five seconds and prints whether the connection succeeded.

## Try it locally

These instructions use Ubuntu or Ubuntu on WSL with Python 3, curl and Nginx installed.

From the repository root, start a local server in one terminal:

```bash
cd labs/nginx-backend
python3 -m http.server 9090 --bind 127.0.0.1
```

In another terminal, check the page and start the polling script:

```bash
curl http://127.0.0.1:9090
bash labs/nginx-backend/watchdog.sh
```

Stop the Python server with Ctrl+C. The polling script should print `server down` on its next check. Start the server again and it should print `server up`. Stop the loop with Ctrl+C when finished.

The Python server is a simple way to reproduce this lab. It is not an application backend or a production server.

## Put Nginx in front

Review the example configuration before installing it. On an Ubuntu test machine with no existing website using port 80:

```bash
sudo cp labs/nginx-backend/nginx.conf.example /etc/nginx/sites-available/dummy-backend
sudo ln -s /etc/nginx/sites-available/dummy-backend /etc/nginx/sites-enabled/dummy-backend
sudo nginx -t
```

The configuration must be the selected server for port 80. An existing default site can take precedence, so check your enabled sites first. If the configuration test passes, reload Nginx using your machine's service manager and visit `http://localhost`.

Do not overwrite an existing site's configuration to try this example.

## What I learned

The proxy and the backend are separate processes. Nginx can still be running while its upstream server is unavailable. Checking the backend directly helped me understand which part had stopped responding.

## Limits of this version

The polling script checks curl's exit status. It does not treat HTTP errors such as 404 or 500 as a failure, and it checks port 9090 directly rather than checking Nginx. It also prints the response body and has no explicit timeout.

Despite the filename, `watchdog.sh` only reports status. It does not restart anything. The main project's systemd service explores automatic process recovery separately.

The page says the backend is secure, but this example only configures an HTTP proxy. It does not implement TLS or authentication.
