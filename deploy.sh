#!/bin/bash


if [[ $EUID -ne 0 ]]; then
  echo "This script needs to be run as root! Attempting to run self as root."
  exec sudo /bin/bash "$0" "$@"
else
  echo "Deleting old files"
  if [[ -f "./breaker" ]]; then rm breaker; fi;
  if [[ -f "./breaker.sh.x.c" ]]; then rm breaker.sh.x.c; fi;
  echo "Compiling script....."
  shc -r -f breaker.sh -o breaker
  echo "Script compiled!"
  echo "Building docker image..."
  sudo docker build . -t flaxeneel2:breaker
  echo "Docker image built!"
  echo "Deployment complete!"
fi