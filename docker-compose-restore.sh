#!/bin/bash

# Проверка наличия параметра
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 backup_directory"
  exit 1
fi

BACKUP_DIR=$1

# Восстановление сетей
NETWORK_BACKUP_FILE="${BACKUP_DIR}/networks.json"
if [ -f "$NETWORK_BACKUP_FILE" ]; then
  echo "Restoring networks from $NETWORK_BACKUP_FILE"
  NETWORKS=$(cat "$NETWORK_BACKUP_FILE")
  for NETWORK in $(echo "$NETWORKS" | jq -c '.')
  do
    NETWORK_NAME=$(echo "$NETWORK" | jq -r '.name')
    NETWORK_EXISTS=$(docker network ls --filter name="^${NETWORK_NAME}$" --format "{{.Name}}")
    if [ -z "$NETWORK_EXISTS" ]; then
      docker network create "$NETWORK_NAME"
    fi
  done
  echo "Networks restored."
fi

# Восстановление образов и томов
for BACKUP_FILE in "$BACKUP_DIR"/*.tar
do
  if [[ "$BACKUP_FILE" == *_backup.tar ]]; then
    echo "Restoring from backup file: $BACKUP_FILE"

    # Загрузка образа из файла
    docker load -i "$BACKUP_FILE"

    # Получение имени образа из файла
    IMAGE_NAME=$(basename "$BACKUP_FILE" .tar)

    echo "Image $IMAGE_NAME restored."
  else
    echo "Restoring volume from backup file: $BACKUP_FILE"

    # Получение имени тома из файла
    VOLUME_NAME=$(basename "$BACKUP_FILE" .tar)

    # Создание тома
    docker volume create "$VOLUME_NAME"

    # Восстановление данных в том из файла
    docker run --rm -v "${VOLUME_NAME}:/volume" -v "$(pwd):/backup" busybox tar xvf "/backup/${BACKUP_FILE}" -C /volume

    echo "Volume $VOLUME_NAME restored from $BACKUP_FILE"
  fi
done

# Восстановление контейнеров с конфигурацией
CONTAINER_CONFIG_FILE="${BACKUP_DIR}/container_configs.json"
if [ -f "$CONTAINER_CONFIG_FILE" ]; then
  echo "Restoring container configurations from $CONTAINER_CONFIG_FILE"
  CONFIGS=$(cat "$CONTAINER_CONFIG_FILE")
  for CONFIG in $(echo "$CONFIGS" | jq -c '.')
  do
    CONTAINER_NAME=$(echo "$CONFIG" | jq -r '.Name' | sed 's/^\/\|\/$//g')
    CONFIG_SETTINGS=$(echo "$CONFIG" | jq -c '.Config')
    HOST_CONFIG=$(echo "$CONFIG" | jq -c '.HostConfig')
    MOUNTS=$(echo "$CONFIG" | jq -c '.Mounts')

    # Собрать опции для запуска контейнера
    RUN_OPTS="--name $CONTAINER_NAME"
    ENV_VARS=$(echo "$CONFIG_SETTINGS" | jq -r '.Env[]' | awk '{print "-e "$0}')
    for ENV_VAR in $ENV_VARS
    do
      RUN_OPTS="$RUN_OPTS $ENV_VAR"
    done

    BIND_MOUNTS=$(echo "$MOUNTS" | jq -r '.[] | select(.Type=="bind") | "-v " + .Source + ":" + .Destination')
    for BIND_MOUNT in $BIND_MOUNTS
    do
      RUN_OPTS="$RUN_OPTS $BIND_MOUNT"
    done

    # Запуск контейнера с конфигурацией
    IMAGE_NAME="${CONTAINER_NAME}_backup"
    docker run -d $RUN_OPTS "$IMAGE_NAME"
  done
  echo "Container configurations restored."
fi

# Восстановление подключений к сетям для контейнеров
if [ -f "$NETWORK_BACKUP_FILE" ]; then
  echo "Connecting containers to networks..."
  NETWORKS=$(cat "$NETWORK_BACKUP_FILE")
  for NETWORK in $(echo "$NETWORKS" | jq -c '.')
  do
    NETWORK_NAME=$(echo "$NETWORK" | jq -r '.name')
    CONTAINER_NAME=$(echo "$NETWORK" | jq -r '.settings.Container')
    docker network connect "$NETWORK_NAME" "$CONTAINER_NAME"
  done
  echo "Containers connected to networks."
fi

echo "Restoration process completed."
