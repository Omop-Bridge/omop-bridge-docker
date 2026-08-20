# OMOP Bridge - Offline Deployment and Upgrade Guide

This guide explains how to deploy and upgrade **OMOP Bridge** in an offline environment using the provided deployment scripts.

The deployment package includes pre-built Docker images that can be loaded directly into the local Docker engine without requiring internet access.

## 📋 Table of Contents

1. [Initial Deployment](#-initial-deployment-load_and_runsh)
2. [Performing Upgrades](#-performing-upgrades-upgradesh)
3. [Data Persistence](#-data-persistence)
4. [Troubleshooting and Verification](#-troubleshooting--verification)

---

## 🚀 Initial Deployment (`load_and_run.sh`)

Use the `load_and_run.sh` script when setting up OMOP Bridge on a **fresh offline server for the first time**.

The script automatically:

1. Locates the compressed Docker image archives.
2. Unpacks the provided `.tar.gz` image files.
3. Loads the container images into the local Docker engine.
4. Starts the OMOP Bridge Docker Compose stack from the project root.

### Prerequisites

Before starting, ensure that:

- Docker Engine is installed and running.
- Docker Compose is available.
- All required container image archives are available in the `dockerImage/` directory.
- The `.env` file is properly configured.

### Deployment Steps

#### 1. Navigate to the Project Root

Open a terminal and navigate to the OMOP Bridge deployment directory:

```bash
cd omop-bridge-docker
```

#### 2. Configure the `.env` File

Ensure that the `.env` file in the project root contains the correct environment configuration before deployment.

For example:

```text
DATABASE_HOST=omop-db
DATABASE_PORT=5432
```

> **Important:** Review all environment variables and passwords before starting the stack.

#### 3. Make the Script Executable

This step is only required the first time:

```bash
chmod +x scripts/load_and_run.sh
```

#### 4. Run the Deployment Script

From the project root, run:

```bash
./scripts/load_and_run.sh
```

The script will load the supplied container images and start the OMOP Bridge services.

### Verify the Deployment

After the script completes, check the status of the containers:

```bash
docker compose ps
```

All required services should show as running or healthy, depending on their configured health checks.

---

## 🔄 Performing Upgrades (`upgrade.sh`)

When new OMOP Bridge image updates, patches, or releases are shipped to your offline environment, use the `upgrade.sh` script.

The upgrade process replaces the application container images while preserving persistent data.

> **Important:** The upgrade script safely stops active containers and removes old image layers **without deleting persistent Docker volumes**.

In particular, the persistent database volume:

```text
omopbridge_db_data
```

is preserved.

This ensures that important data remains intact, including:

- Clinical records
- OMOP CDM data
- Athena vocabulary data
- Concept mappings
- Study data
- Other persistent database content

### Upgrade Steps

#### 1. Replace the Docker Image Archives

Copy the newly supplied `.tar.gz` image files into:

```text
dockerImage/
```

Replace the older image archives with the new versions.

For example:

```text
omop-bridge-backend.tar.gz
omop-bridge-frontend.tar.gz
omop-bridge-db.tar.gz
omop-bridge-r-runner.tar.gz
```

> **Important:** Ensure the new image archives match the filenames or naming conventions expected by the upgrade script.

#### 2. Make the Upgrade Script Executable

This is only required the first time:

```bash
chmod +x scripts/upgrade.sh
```

#### 3. Run the Upgrade

From the project root, execute:

```bash
./scripts/upgrade.sh
```

The script will typically:

1. Stop the currently running OMOP Bridge containers.
2. Remove outdated container images.
3. Load the newly supplied images.
4. Preserve persistent Docker volumes.
5. Start the updated OMOP Bridge stack.

---

## 💾 Data Persistence

OMOP Bridge uses Docker volumes to preserve important data independently of individual containers.

The upgrade process is designed **not to delete persistent volumes**.

For example, the following volume should remain intact:

```text
omopbridge_db_data
```

You can check existing Docker volumes with:

```bash
docker volume ls
```

To inspect the database volume:

```bash
docker volume inspect omopbridge_db_data
```

> **Warning:** Do not run commands such as `docker compose down -v` unless you intentionally want to remove persistent volumes and permanently delete stored data.

---

## 🔍 Troubleshooting and Verification

### Check Running Containers

Verify that all OMOP Bridge services started successfully:

```bash
docker compose ps
```

This command displays the status of each service.

### View All Container Logs

To inspect logs from all services:

```bash
docker compose logs -f
```

### View Backend Logs

If the backend fails to start or is waiting for a database health check:

```bash
docker compose logs -f backend
```

### View Database Logs

To inspect database startup issues:

```bash
docker compose logs -f omop-db
```

### Restart the Stack

If the images are already loaded and you simply need to restart the services:

```bash
docker compose restart
```

Alternatively, stop and start the stack:

```bash
docker compose down
docker compose up -d
```

> This command preserves volumes as long as the `-v` option is not used.

### Check Loaded Docker Images

Verify that the offline images were successfully loaded:

```bash
docker images
```

You can filter for OMOP Bridge images:

```bash
docker images | grep omop-bridge
```

### Check Database Volume

Confirm that the persistent database volume still exists:

```bash
docker volume ls | grep omopbridge_db_data
```

---

## 📦 Typical Offline Deployment Structure

Your deployment package should have a structure similar to:

```text
omop-bridge-docker/
├── docker-compose.yml
├── .env
├── dockerImage/
│   ├── omop-bridge-backend.tar.gz
│   ├── omop-bridge-frontend.tar.gz
│   ├── omop-bridge-db.tar.gz
│   ├── omop-bridge-r-runner.tar.gz
│   └── omop-bridge-atlas3-webapi.tar.gz
└── scripts/
    ├── load_and_run.sh
    └── upgrade.sh
```

## 📌 Quick Reference

| Task | Command |
|---|---|
| Initial deployment | `./scripts/load_and_run.sh` |
| Upgrade installation | `./scripts/upgrade.sh` |
| Check services | `docker compose ps` |
| View all logs | `docker compose logs -f` |
| View backend logs | `docker compose logs -f backend` |
| List images | `docker images` |
| List volumes | `docker volume ls` |

## ⚠️ Important Notes

- Always run the deployment and upgrade scripts from the project root.
- Ensure the `.env` file is configured before deployment.
- Keep the `dockerImage/` directory updated with the correct image archives.
- Do not manually delete `omopbridge_db_data` unless you intend to permanently remove the stored database data.
- Avoid using `docker compose down -v` during normal upgrades.
- Verify container health after every deployment or upgrade.

With this workflow, OMOP Bridge can be installed and upgraded reliably on servers with limited or no internet connectivity.