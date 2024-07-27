
# Docker Backup and Restore Scripts

This repository contains scripts for backing up and restoring Docker containers, volumes, networks, and configurations. There are two sets of scripts: one for individual containers and another for Docker Compose services.

## Scripts

### Backup and Restore Individual Containers

- `docker-backup.sh`: Backs up Docker containers, volumes, and networks.
- `docker-restore.sh`: Restores Docker containers, volumes, and networks from backup files.

### Backup and Restore Docker Compose Services

- `docker-compose-backup.sh`: Backs up Docker Compose services, volumes, and networks.
- `docker-compose-restore.sh`: Restores Docker Compose services, volumes, and networks from backup files.

## Usage

### Backup Individual Containers

1. Save the `docker-backup.sh` script and make it executable:

   \`\`\`bash
   chmod +x docker-backup.sh
   \`\`\`

2. Run the script, passing the names of the containers you want to back up:

   \`\`\`bash
   ./docker-backup.sh container1 container2
   \`\`\`

3. The backups will be saved in the `docker_backup` directory.

### Restore Individual Containers

1. Save the `docker-restore.sh` script and make it executable:

   \`\`\`bash
   chmod +x docker-restore.sh
   \`\`\`

2. Run the script, passing the paths to the backup files:

   \`\`\`bash
   ./docker-restore.sh /path/to/container1_backup.tar /path/to/volume1.tar /path/to/container2_backup.tar /path/to/volume2.tar
   \`\`\`

### Backup Docker Compose Services

1. Save the `docker-compose-backup.sh` script and make it executable:

   \`\`\`bash
   chmod +x docker-compose-backup.sh
   \`\`\`

2. Run the script, passing the path to your `docker-compose.yml` file:

   \`\`\`bash
   ./docker-compose-backup.sh /path/to/docker-compose.yml
   \`\`\`

3. The backups will be saved in the `docker_backup` directory.

### Restore Docker Compose Services

1. Save the `docker-compose-restore.sh` script and make it executable:

   \`\`\`bash
   chmod +x docker-compose-restore.sh
   \`\`\`

2. Run the script, passing the path to the directory containing the backup files:

   \`\`\`bash
   ./docker-compose-restore.sh /path/to/backup_directory
   \`\`\`

## Notes

- The `docker-backup.sh` and `docker-restore.sh` scripts are designed for backing up and restoring individual Docker containers, including their volumes and network configurations.
- The `docker-compose-backup.sh` and `docker-compose-restore.sh` scripts are designed for backing up and restoring Docker Compose services, including their volumes and network configurations.
- Make sure to have `jq` installed on your system as it is used for JSON processing in the scripts.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
