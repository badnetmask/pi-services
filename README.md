# pi-services
This repo is my way to share the way I run various services on my home network.

With the files and instructions in this repo you should be able to run:
* [Pi-hole](https://pi-hole.net/) to be your network's DNS server (DHCP will
  not be covered).
* [InfluxDB](https://www.influxdata.com/products/influxdb-overview/) to store
  data from some of the services shipped here, plus whatever else you may want.
* [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/) to
  collect data from various sources (pre-configured to collect data from the
  Raspberry Pi itself).
* [Grafana](https://grafana.com/oss/grafana/) to visialize the collected data
  (with instructions on how to configure some dashboards).

# Disclaimer
This has been developed and tested on a **Raspberry Pi 4**, running the latest
Raspberry Pi OS (previously called Raspbian). It may or may not work in other
Raspberry Pis, or even other hardware (with proper modifications), so I am
presenting this with *no guarantees*.

It is assumed that you already have your Raspberry Pi fully configured, running
on your network, and that you do not have any kind of web server already
running (Apache, LightHTTP, whatever). If you do, you may need to make changes
to the Pi-hole configuration.

This is a modified/shareable version of my **personal** configuration (not a
verbatim copy). There are a lot of poor security choices I made here, in order
to be able to share this work (like, for example, hardcoding passwords on a
Yaml file). This may or may not serve your purposes.

Feel free to copy and modify to make it work whatever way you prefer.  I am not
going to claim I am an expert in managing containers, or any of the services
demonstrated here.  Feel free to propose changes, if you think they are
beneficial to you, to me or the broader community (no promises they will be
incorporated, but I will appreciate your contribution, and take them into
consideration).

# Quick overview
All the services are orchestrated by the `docker-compose.yml` file. It describes
which services are running, their dependencies, and **some** of their
configuration parameters (not all of them). Some of the configuration files are
also shipped in this directory, using some (probably) sane defaults.

# Updating everything
The `update-all.sh` script will check for the latest versions of all images, and restart the compose if necessary.

# Step 1 - Preparation
# Step 1.1 - Prepare the system to run containers
This will allow you to run your containers as the non-root users (in this case
I am using *pi* for simplification, but do whatever you feel works best for
you).

```
$ sudo apt-get install docker-compose
$ sudo systemctl enable docker
$ sudo systemctl start docker
$ usermod -aG docker pi
```

Log out from the system, then log back in.

# Step 1.2 - Create the required files and folders
Some files and folders are required, but they won't be automatically created,
so you need to do that manually:

```
$ mkdir -p etc/ssl/mycerts var-log var-lib/grafana var-log/grafana
$ touch var-log/pihole.log
$ sudo chown 472 var-lib/grafana var-log/grafana
```

# Step 2 - SSL certificates
**TODO:** Add instructions for [Let's Encrypt](https://letsencrypt.org/)

For the simplistic purposes of this project, we're going to use [self-signed
SSL certificates](https://en.wikipedia.org/wiki/Self-signed_certificate).  They
may not deliver the best security ever, but they are simple to deploy, and
don't require maintenance. This can always be changed/improved at a later date.

```
$ sudo apt-get install openssl
$ openssl req -new -x509 -days 365 -nodes -out etc/ssl/mycerts/server.pem -keyout etc/ssl/mycerts/server.key
***
answer the prompts whatever way is most suitable to you
what you see below is just an example
***
Country Name (2 letter code) [AU]:US
State or Province Name (full name) [Some-State]:NY
Locality Name (eg, city) []:New York
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Home
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:
Email Address []:
***
don't forget this last command!
***
$ chmod 644 etc/ssl/mycerts/server.key
```

**NOTE:** It's strongly suggested that you do not use this certificate file for
anything other than these services.

# Step 3 - Review your configuration
Look inside `docker-compose.yml`, and make sure some of the configuration
options listed below are good for your.

## Step 3.1 - Pi-Hole
The Pi-Hole section is based on the [Docker
Pi-hole](https://github.com/pi-hole/docker-pi-hole) project. There are many
configuration options, but the minimum recommended here are:
* `WEBPASSWORD`: set a secure password here or it will be this string (literally).
* `DNS1 + DNS2`: I personally prefer to use
  [OpenDNS](https://www.opendns.com/). If you comment out these options, it
will use [Google DNS](https://developers.google.com/speed/public-dns) by
default.

**NOTE:** If you already have a web server running, you will need to tweak this
configuration a lot more. Look at the official [Docker
Pi-hole](https://github.com/pi-hole/docker-pi-hole) project page, for the
appropriate configuration options.

## Step 3.2 - InfluxDB
This section is based on the official [InfluxDB
image](https://hub.docker.com/r/arm32v7/influxdb). There are many configuration
options, but the minimum recommended here are:
* `INFLUXDB_ADMIN_PASSWORD`: set a secure password here or it will be this
  string (literally).
* `INFLUXDB_WRITE_USER_PASSWORD`: set a secure password here or it will be this
  string (literally).
* `INFLUXDB_READ_USER_PASSWORD`: set a secure password here or it will be this
  string (literally).

## Step 3.3 - Telegraf
The Telegraf base service configuration in section is *mostly* based on [this
blog](https://thenewstack.io/how-to-setup-influxdb-telegraf-and-grafana-on-docker-part-2/).
The parts related to monitoring the Raspberry Pi are based on the instructions
for two grafana dashboards, which you will install later (instructions ahead).

There is only one thing you need to configure here:
* `INFLUXDB_WRITE_USER_PASSWORD`: make sure this is the same password as the
  WRITE_USER for InfluxDB (as set above).

## Step 3.4 - Grafana
This section is based on a bunch of information that I have gathered from
different sources.

There is absolutely nothing you need to change here. **Just remember**, the
default username and password are *admin:admin*, and I suggest you change this
after your first login.

## Step 3.5 - Motion
**NOTE:** This is disabled by default. To enable, uncomment the entire section.

This section is based on the official
[motion-docker](https://github.com/Motion-Project/motion-docker) project
(modified for the Pi). It assumes you have a webcam connected, that it has been
properly detected by the Raspberry Pi, and it's being exposed on /dev/video0.
It stands up a web server on port 8080 that you can use to control your webcam
capture. The webcam itself is visible on port 8081.

*Only enable after you are sure the [configuration suits your
needs](https://motion-project.github.io/motion_config.html), otherwise you may
eat up your disk.*

# Step 4 - Run the services
The command below will start all services, in the appropriate order, then
detach so you can get your terminal back.
```
$ docker-compose up --detach
```
It may take a while to initialize everything for the first time. Be patient.

# Step 5 - Configure Grafana
* At some point you should be able to go open this address on your browser:
  `https://<rpi-ip>:3000/`. Since we are using a self-signed certificate, your
  browser will complain that the connection is not private, or invalid. Just
  accept it (follow the appropriate instructions for your browser).
* After you see the web interface, there is nothing useful there.
* First of all, look to the bottom left of the screen, rover over the
  left-arrow, and click on `Sign In`. The username is `admin`, the password is
  `admin`. Click `Log in`.
* This will ask you to change your new `admin` password. Set whatever you want.
* After that you will be redirected to the main screen.
* Look to the left bar, around the middle, rover over the gear icon, and click
  `Data Sources`.
* On the new screen, find and click on `InfluxDB`.
* You will be sent to the `Settings` screen. Change the following:
  * Name: `InfluxDB-Telegraf`
  * URL: `https://172.22.0.3:8086`
  * Skip TLS Verify: click to enable
  * Database: `telegraf`
  * User: `grafana`
  * Password: same as `INFLUXDB_READ_USER_PASSWORD`
  * HTTP Method: `GET`
  * Click on `Save & Test`, you should see `Data source is working`.
* Now you will add the two dashboards for which the services have been
  pre-configured:
  * Look at the left bar, rover over the plus sign icon, click on `Import`.
  * Enter number `1443`, and click `Load`. On the next screen, find the
    datasource box, and select `InfluxDB-Telegraf`, then click `Import`. This
    action will import [this
    dashboard](https://grafana.com/grafana/dashboards/1443).
  * Again, look at the left bar, rover over the plus sign icon, click on
    `Import`.
  * Enter number `12034`, then repeat the sameprocess as before. This action
    will import [this dashboard](https://grafana.com/grafana/dashboards/12034)

# Step 6 - Profit!
At this point you have everything working, and you should have very nice
graphs! Enjoy!

# TODO
I have intentions to improve this guide (eventually). Some of the things in my mind:
* Add support for [Let's Encrypt](https://letsencrypt.org/) certificates.
* Add instructions on how to migrate from self-signed to Let's Encrypt.
* Add maintenance instructions (~~updates~~, backups, etc).
* **Maybe**:
  * Either Nagios or Zabbix, still deciding what to do.
  * Some sort of internet bandwith test.

# License
[MIT](https://choosealicense.com/licenses/mit/)
