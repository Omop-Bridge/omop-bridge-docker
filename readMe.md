# OMOP Bridge - Deployment and Upgrade Guide

This guide explains how to deploy and upgrade **OMOP Bridge** in both **online environments**, where container images are pulled from registries, and **offline environments**, where pre-packaged Docker image archives are used.

## 📋 Table of Contents

1. [Deployment Options](#-deployment-options)
2. [Online Deployment](#-online-deployment-public-registries)
3. [Offline Deployment](#-offline-deployment-load_and_runsh)
4. [Performing Upgrades](#-performing-upgrades-upgradesh)
5. [Data Persistence](#-data-persistence)
6. [Troubleshooting and Verification](#-troubleshooting-and-verification)
7. [Typical Deployment Structure](#-typical-deployment-structure)
8. [Quick Reference](#-quick-reference)

---

## 🌐 Deployment Options

OMOP Bridge supports two primary deployment pathways depending on the network configuration of your server:

* **Online Deployment** — Pulls the required container images directly from configured Docker registries.
* **Offline Deployment** — Loads pre-packaged container image archives locally, making it suitable for isolated or air-gapped infrastructure.

---

## 🚀 Online Deployment (Public Registries)

Use online deployment when the target server has internet access and can pull the required container images from the configured registries.

### Prerequisites

Before deploying, ensure that:

* Docker Engine is installed and running.
* Docker Compose is available.
* The required container registries are accessible.
* You are authenticated with any private container registry, if required.
* A properly configured `.env` file exists in the project root.

### Deployment Steps

#### 1. Navigate to the Project Root

```bash
cd omop-bridge-docker
```

#### 2. Configure the .env File

OMOP Bridge includes a sample environment configuration file named .env.sample. Create your deployment-specific .env file by copying it:


```bash
cp .env.sample .env
```

> **Important:** Then review and update the .env file with the appropriate environment variables, connection parameters, service configuration values, and database credentials for your deployment:

#### 3. Pull and Start the Stack

Start OMOP Bridge in detached mode:

```bash
docker compose up -d
```

Docker Compose will pull any required images that are not already available locally and then start the services.

#### 4. Verify the Deployment

```bash
docker compose ps
```

All expected services should show as running or healthy, depending on the configured health checks.

---

## 📴 Offline Deployment (`load_and_run.sh`)

Use the `load_and_run.sh` script when installing OMOP Bridge on a **fresh offline or air-gapped server** for the first time.

This deployment method uses pre-packaged Docker image archives stored locally instead of downloading images from a registry.

The script automatically:

1. Locates the compressed Docker image archives.
2. Unpacks the provided `.tar.gz` files.
3. Loads the Docker images into the local Docker engine.
4. Starts the OMOP Bridge Docker Compose stack.

### Prerequisites

Ensure that the following are available:

* Docker Engine is installed and running.
* Docker Compose is available.
* All required container image archives are present in the `dockerImage/` directory.
* The `.env` file is correctly configured.

### Deployment Steps

#### 1. Navigate to the Project Root

```bash
cd omop-bridge-docker
```

#### 2. Verify the Offline Image Packages

Confirm that the required image archives are available:

```text
dockerImage/
├── omop-bridge-backend.tar.gz
├── omop-bridge-frontend.tar.gz
├── omop-bridge-db.tar.gz
├── omop-bridge-r-runner.tar.gz
└── omop-bridge-atlas3-webapi.tar.gz
```

#### 3. Make the Deployment Script Executable

This is required the first time the script is used:

```bash
chmod +x scripts/load_and_run.sh
```

#### 4. Run the Deployment Script

```bash
./scripts/load_and_run.sh
```

Once the script completes, verify the running services:

```bash
docker compose ps
```

---

## 🔄 Performing Upgrades (`upgrade.sh`)

When new OMOP Bridge releases, patches, or updated container images are available, use the `upgrade.sh` script to update the deployment.

The upgrade process is designed to replace application container images while preserving persistent Docker volumes containing important application and database data.

### Upgrade Process

#### 1. Obtain the Updated Images

For an **online deployment**, pull the latest configured image versions:

```bash
docker compose pull
```

For an **offline deployment**, replace the existing image archives in the `dockerImage/` directory with the new release packages:

```text
dockerImage/
├── omop-bridge-backend.tar.gz
├── omop-bridge-frontend.tar.gz
├── omop-bridge-db.tar.gz
├── omop-bridge-r-runner.tar.gz
└── omop-bridge-atlas3-webapi.tar.gz
```

#### 2. Make the Upgrade Script Executable

This is required only the first time:

```bash
chmod +x scripts/upgrade.sh
```

#### 3. Run the Upgrade

```bash
./scripts/upgrade.sh
```

The script should update the application containers while retaining configured persistent volumes.

#### 4. Verify the Upgrade

```bash
docker compose ps
```

You can also inspect the service logs:

```bash
docker compose logs -f
```

---

## 💾 Data Persistence

OMOP Bridge uses Docker volumes to persist important data independently of the lifecycle of individual containers.

Examples of persistent volumes include:

* `omopbridge_db_data`
* `atlas3-webapi-data`
* `dqd_results`

This means that stopping, recreating, or upgrading application containers should not remove data stored in these volumes.

> **Warning:** Do not run `docker compose down -v` unless you intentionally want to remove persistent Docker volumes. This operation can permanently delete stored database, OMOP CDM, application, and results data.

To view available Docker volumes:

```bash
docker volume ls
```

---

## 🔍 Troubleshooting and Verification

### Check Running Containers

```bash
docker compose ps
```

### View Logs for All Services

```bash
docker compose logs -f
```

### View Logs for a Specific Service

For the backend:

```bash
docker compose logs -f backend
```

For the OMOP Bridge database:

```bash
docker compose logs -f omop-bridge-db
```

### Check Loaded Docker Images

```bash
docker images | grep omop-bridge
```

### Check Docker Volumes

```bash
docker volume ls
```

### Restart the Stack

If services need to be restarted:

```bash
docker compose restart
```

### Stop the Stack Without Removing Data

```bash
docker compose down
```

Because the `-v` option is not used, persistent Docker volumes are retained.

### Start the Stack Again

```bash
docker compose up -d
```

---

## 📦 Typical Deployment Structure

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

---

## 📌 Quick Reference

| Task                       | Command                          |
| -------------------------- | -------------------------------- |
| Online deployment          | `docker compose up -d`           |
| Pull updated images        | `docker compose pull`            |
| Offline deployment         | `./scripts/load_and_run.sh`      |
| Upgrade installation       | `./scripts/upgrade.sh`           |
| Check services             | `docker compose ps`              |
| View all logs              | `docker compose logs -f`         |
| View backend logs          | `docker compose logs -f backend` |
| List Docker images         | `docker images`                  |
| List Docker volumes        | `docker volume ls`               |
| Restart services           | `docker compose restart`         |
| Stop without deleting data | `docker compose down`            |

---

## ⚠️ Important Operational Notes

* Always back up critical production data before performing major upgrades.
* Verify that the `.env` file is compatible with the new release before upgrading.
* For offline deployments, ensure all image archives belong to the same OMOP Bridge release.
* Do not delete Docker volumes unless you explicitly intend to remove persistent application data.
* After deployment or upgrade, verify service status and inspect logs for startup or migration errors.

## License

Refer to the OMOP Bridge project license for licensing and usage information.
