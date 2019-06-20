# iot-reverse-ssh-tunnel
Reverse ssh tunnel to access IOT device behind NAT. Setup in a containerised environment with unique device keys. Can be used for massive deployment.

# Installation prerequisites
Make sure you have already installed both Docker Engine and Docker Compose. 
https://docs.docker.com/install/
https://docs.docker.com/compose/install/

# Installation
Check out the source:
`` git clone https://www.github.com/jnuyens/iot-reverse-ssh-tunnel ``
Change the password used here:
And the port number for ssh here if needed:

The docker containers needed are defined in docker-compose.yml and the corresponding dockerfiles. Just bring it up:
`` docker-compose up ``

# API documentation

## New Device Creation
This way you can add a new IoT device and load it with a device-specific key, port number and servername.
Each device has information associated with it which is stored at different locations:
- a device specific password which can be used to gain shell access using SSH to the IoT device. This will be stored on the key-db-server encoded using the 'master password'.
- the device specific encoded password which will be stored on the device in the /etc/shadow file
- a device specific port number and servername which will be used for setting up the reverse tunnel to the correct server and on the correct port. This information is storedon the device and in the key-db-server. Because the servername is device-specific, we can grow the infrastructure to more than the 10.000 device limit per master-reverse-ssh-server.

We presume each device has a unique MAC-address and/or ID to identify itself for new-device creation. This typically is performed at initial software loading or at the factory or testing/assembly facility. This needs access to the api-server, and this should not be possible from a public internet connection (except temporary in an initial-migration-scenario with a limited number of test devices in the field).

## Connect to an existing Device
The connect.sh script allows you to just specify the device ID or MAC-address, and provided you have access to the api-server and master-ssh-server, allows you to connect to any device.
This access will be logged to prevent abuse and allow auditing.
This script is immediately also an example how the API can be used.
E.g. for a device with unique id: 234DNJE4 and MAC-address: 92:be:bf:83:6e:b3
	- ./connect.sh 234DNJE4
	- ./connect.sh -m 92:be:bf:83:6e:b3
	- ./connect.sh -m 92:be:bf:83:6e:b7 

# General Architecture
## Network requirements
On a public IP one (or more) master-ssh-server(s) needs to reachable on port 22. It is possible to run this on another port, but port 22 identifies this as SSH traffic, which it is. This is the nicest from internet perspective.
It means the IoT devices will use port 22 to the server to initiate the reverse ssh tunnel, so for the IoT devices the requirement is: allow outgoing traffic on port 22.
In many home NAT situations all outgoing traffic is allowed. For corporate environments it's a clear requirement for this.

It is possible to run this instead on port 443 (used for HTTPS) which might have a higher chance of traversing corporate firewalls. We do however consider this an ugly hack.It should not be too hard to make this change (or the port configurable).

A unique key for each IoT device ensures one customer cannot access data from another customer; not even if they manage to get physical access to the other network, nor through the reverse ssh tunnel. Additionally, access from the IoT device is limited to the setup of an ssh tunnel; not providing any shell access.

## Different docker containers:
3 Different containers are created:
## master-ssh-server
Here the IoT devices connect to to activate the Reverse SSH Tunnel. If you need to connect to an IoT device, you will also use this server combined with the device-specific credentials stored on the key-db-server. Server should be reachable from the internet on port 22 only. The ports 10000 till 20000 need only be reachable from your internal network; each giving access to a different IoT device (with device-specific credentials).

Test if you can reach it: 
`` ssh root@master-ssh-server ``

## api-server
This server runs the REST interface to easily add new IoT devices and get the credentials needed to connect to a specific device. It is build with NGINX high performance web server and FPM-PHP

Documentation is generated with swagger; we did in the www-data/doc directory: composer require alt3/cakephp-swagger

Test: 
`` http://api-server/doc/vendor/alt3/cakephp-swagger/tests/App/ or
http://api-server/doc/vendor/alt3/swagger ``

## key-db-server
This server runs the database containing all the device keys in a MariaDB server (high performance, more secure and better version of MySQL). This server should only be reachable from the api-server.

