#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 container_name [container_name ...]"
  exit 1
fi

BACKUP_DIR="./docker_backup"
mkdir -p "$BACKUP_DIR"

NETWORK_BACKUP_FILE="${BACKUP_DIR}/networks.json"
> "$NETWORK_BACKUP_FILE"

CONTAINER_CONFIG_FILE="${BACKUP_DIR}/container_configs.json"
> "$CONTAINER_CONFIG_FILE"

for CONTAINER in "$@"
do
  echo "Processing container: $CONTAINER"

  IMAGE_NAME="${CONTAINER}_backup"
  docker commit "$CONTAINER" "$IMAGE_NAME"

  BACKUP_FILE="${BACKUP_DIR}/${IMAGE_NAME}.tar"
  docker save -o "$BACKUP_FILE" "$IMAGE_NAME"

  docker rmi "$IMAGE_NAME"

  echo "Backup of $CONTAINER saved to $BACKUP_FILE"

  VOLUMES=$(docker inspect --format '{{ range .Mounts }}{{ if eq .Type "volume" }}{{ .Name }} {{ end }}{{ end }}' "$CONTAINER")

  for VOLUME in $VOLUMES
  do
    echo "Processing volume: $VOLUME"
    VOLUME_BACKUP_FILE="${BACKUP_DIR}/${VOLUME}.tar"
    docker run --rm -v "${VOLUME}:/volume" -v "$BACKUP_DIR:/backup" busybox tar cvf "/backup/${VOLUME}.tar" -C /volume .
    echo "Backup of volume $VOLUME saved to $VOLUME_BACKUP_FILE"
  done

  NETWORKS=$(docker inspect --format '{{ json .NetworkSettings.Networks }}' "$CONTAINER")
  echo "$NETWORKS" | jq -c 'to_entries | .[] | {name: .key, settings: .value}' >> "$NETWORK_BACKUP_FILE"

  CONFIG=$(docker inspect "$CONTAINER")
  echo "$CONFIG" | jq -c '.[0] | {Name: .Name, Config: .Config, HostConfig: .HostConfig, Mounts: .Mounts}' >> "$CONTAINER_CONFIG_FILE"

done

echo "Backup process completed."
