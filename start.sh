#!/bin/bash
export DOCKER_CLIENT_TIMEOUT=120
export COMPOSE_HTTP_TIMEOUT=120
sudo docker-compose up -d
