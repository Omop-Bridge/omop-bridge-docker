# OMOP Bridge — Deployment and Upgrade Guide

This guide explains how to deploy and upgrade **OMOP Bridge** in both **online environments**, where container images are pulled from Docker registries, and **offline environments**, where pre-packaged Docker image archives are used.

## 📋 Table of Contents

1. [Deployment Options](#deployment-options)
2. [Online Deployment](#online-deployment-public-registries)
3. [Offline Deployment](#offline-deployment-load_and_runsh)
4. [Accessing OMOP Bridge and Services](#accessing-omop-bridge-and-services)
5. [Default Login Credentials](#default-login-credentials)
6. [Performing Upgrades](#performing-upgrades-upgradesh)
7. [Data Persistence](#data-persistence)
8. [Troubleshooting and Verification](#troubleshooting-and-verification)
9. [Typical Deployment Structure](#typical-deployment-structure)
10. [Quick Reference](#quick-reference)
11. [Operational Notes](#important-operational-notes)
12. [License](#license)

---

## 🌐 Deployment Options

OMOP Bridge supports two primary deployment pathways depending on the network configuration of the target server:

- **Online Deployment** — Pulls the required container images directly from configured Docker registries.
- **Offline Deployment** — Loads pre-packaged Docker image archives locally, making it suitable for isolated or air-gapped infrastructure.

---

## 🚀 Online Deployment (Public Registries)

Use online deployment when the target server has internet access and can pull the required container images from the configured registries.

### Prerequisites

Before deploying, ensure that:

- Docker Engine is installed and running.
- Docker Compose is available.
- The required container registries are accessible.
- You are authenticated with any private container registry, if required.
- A properly configured `.env` file exists in the project root.

### Deployment Steps

#### 1. Navigate to the Project Root

```bash
cd omop-bridge-docker
```

#### 2. Configure the `.env` File

OMOP Bridge includes a sample environment configuration file named `.env.sample`. Create your deployment-specific `.env` file:

```bash
cp .env.sample .env && sed -i "s/JWT_SECRET_KEY=.*/JWT_SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(32))')/g" .env
```

Review and update `.env` with the appropriate:

- Environment variables
- Database connection parameters
- Service configuration values
- Database credentials
- Other deployment-specific settings

> **Important:** Never commit production credentials, API keys, JWT secrets, or other sensitive values to source control.

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

All expected services should show as **running** or **healthy**, depending on the configured health checks.

## 📴 Offline Deployment (`load_and_run.sh`)

Use `load_and_run.sh` when installing OMOP Bridge on a **fresh offline or air-gapped server** for the first time.

This deployment method uses pre-packaged Docker image archives stored locally instead of downloading images from a registry.

The script automatically:

1. Locates the compressed Docker image archives.
2. Unpacks the provided `.tar.gz` files.
3. Loads the Docker images into the local Docker Engine.
4. Starts the OMOP Bridge Docker Compose stack.

### Prerequisites

Ensure that:

- Docker Engine is installed and running.
- Docker Compose is available.
- All required container image archives are present in the `dockerImage/` directory.
- The `.env` file is correctly configured.
- The image archives belong to the same OMOP Bridge release.

### Deployment Steps

#### 1. Navigate to the Project Root

```bash
cd omop-bridge-docker
```

#### 2. Verify the Offline Image Packages

Confirm that the required image archives are available:

Plaintext


dockerImage/
├── omop-bridge-backend.tar.gz
├── omop-bridge-frontend.tar.gz
├── omop-bridge-db.tar.gz
├── omop-bridge-r-runner.tar.gz
└── omop-bridge-atlas3-webapi.tar.gz


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

## 🌐 Accessing OMOP Bridge and Services

Once the deployment stack is successfully running, you can access the core application and its accompanying monitoring and analytics services through your web browser:

| **Service**                   | **Access URL**             |
| ----------------------------- | -------------------------- |
| **OMOP Bridge Main App**      | `http://localhost`         |
| **ATLAS Analytics**           | `http://localhost/atlas/`  |
| **Grafana Dashboards**        | `http://localhost/grafana` |
| **Database Manager (DbGate)** | `http://localhost/db/`     |

For remote deployments, replace `localhost` with the server's hostname, domain name, or IP address as appropriate.

## 🔑 Default Login Credentials

Use the following default administrator credentials to log into the platform components for the first time:

| **Service**            | **Username**       | **Password** |
| ---------------------- | ------------------ | ------------ |
| **OMOP Bridge**        | `admin@omopbridge` | `admin`      |
| **ATLAS Analytics**    | `admin`            | `admin`      |
| **Grafana Monitoring** | `admin`            | `admin`      |

> **Security Note:** Change all default administrator passwords immediately after your initial login, especially in production environments.

## 🔄 Performing Upgrades (`upgrade.sh`)

When a new OMOP Bridge release, patch, or updated container image becomes available, use `upgrade.sh` to update the deployment.

The upgrade process is designed to replace application containers while preserving persistent Docker volumes containing application and database data.

### Before Upgrading

Before performing an upgrade:

1. Back up critical application and database data.
2. Review the release notes for the new version.
3. Verify that the `.env` configuration is compatible with the new release.
4. Ensure that all required images are available.
5. Confirm that the server has sufficient disk space.

### Upgrade Process

#### 1. Update the Repository Code

Pull the latest changes from the version control system:



```bash
 git pull
```

#### 2. Sync Configuration Changes (`.env.sample` to `.env`)

New releases may introduce required configuration parameters in .env.sample. Compare the updated .env.sample with your existing .env file and add any newly introduced environment variables while preserving your existing configuration values.

```bash
grep -E '^[A-Za-z_][A-Za-z0-9_]*=' .env.sample | while IFS= read -r line; do
    key="${line%%=*}"
    if ! grep -qE "^${key}=" .env; then
        echo "$line" >> .env
    fi
done
```

After running the command, manually cross-check .env against the updated .env.sample to confirm that all newly introduced variables have been added correctly and that your existing local configuration values have not been overwritten or changed.
#### 3. Obtain the Updated Images

```bash
docker compose pull
```

For an **offline deployment**, replace the existing image archives in the `dockerImage/` directory with the image packages for the new release:

Plaintext

```
dockerImage/
├── omop-bridge-backend.tar.gz
├── omop-bridge-frontend.tar.gz
├── omop-bridge-db.tar.gz
├── omop-bridge-r-runner.tar.gz
└── omop-bridge-atlas3-webapi.tar.gz
```

Ensure that all archives belong to the **same OMOP Bridge release**.

#### 4. Make the Upgrade Script Executable

This is required only the first time:

```bash
chmod +x scripts/upgrade.sh
```

#### 5. Run the Upgrade

```bash
./scripts/upgrade.sh
```

The script updates the application containers while retaining configured persistent volumes.

#### 6. Verify the Upgrade

Check the service status:

```bash
docker compose ps
```

Inspect the service logs:

```bash
docker compose logs -f
```

If necessary, inspect individual services:

```bash
docker compose logs -f backend
```

---

## 💾 Data Persistence

OMOP Bridge uses Docker volumes to persist important data independently of individual container lifecycles.

Examples of persistent volumes include:

- `omopbridge_db_data`
- `atlas3-webapi-data`
- `dqd_results`

Stopping, recreating, or upgrading containers should not remove data stored in these volumes.

### ⚠️ Important Volume Warning

**Do not run the following command unless you intentionally want to remove persistent Docker volumes:**

```bash
docker compose down -v
```

The `-v` option can permanently delete stored database, OMOP CDM, application, and results data.

To view Docker volumes:

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

**Backend:**

```bash
docker compose logs -f backend
```

**OMOP Bridge database:**

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

### Verify the Application

After starting or upgrading the stack:

1. Confirm all expected containers are running.
2. Check the service logs for startup errors.
3. Open the OMOP Bridge web interface.
4. Sign in and verify that existing data is accessible.
5. Confirm that the database and other persistent services are healthy.

---

## 📦 Typical Deployment Structure

```text
omop-bridge-docker/
├── docker-compose.yml
├── .env
├── .env.sample
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

> **Note:** The `dockerImage/` directory is primarily required for offline deployments. Online deployments pull images directly from the configured registries.

---

## 📌 Quick Reference

| **Task**                                       | **Command / Detail**             |
|------------------------------------------------| -------------------------------- |
| Platform URL                                   | `http://localhost`               |
| ATLAS URL                                      | `http://localhost/atlas/`        |
| Grafana URL                                    | `http://localhost/grafana`       |
| Default Login [username / password] (Bridge)   | `admin@omopbridge` / `admin`     |
| Default Login [username / password]  (ATLAS)   | `admin` / `admin`                |
| Default Login [username / password]  (Grafana) | `admin` / `admin`                |
| Online deployment                              | `docker compose up -d`           |
| Pull updated images                            | `docker compose pull`            |
| Offline deployment                             | `./scripts/load_and_run.sh`      |
| Upgrade repository                             | `git pull`                       |
| Compare environment updates                    | `diff -u .env .env.sample`       |
| Upgrade installation                           | `./scripts/upgrade.sh`           |
| Check services                                 | `docker compose ps`              |
| View all logs                                  | `docker compose logs -f`         |
| View backend logs                              | `docker compose logs -f backend` |
| List Docker images                             | `docker images`                  |
| List Docker volumes                            | `docker volume ls`               |
| Restart services                               | `docker compose restart`         |
| Stop without deleting data                     | `docker compose down`            |

---

## ⚠️ Important Operational Notes

- Always back up critical production data before performing major upgrades.
- Review release notes before upgrading.
- Verify that the `.env` file is compatible with the new release by checking updates from `.env.sample`.
- For offline deployments, ensure all image archives belong to the same OMOP Bridge release.
- Do not delete Docker volumes unless you explicitly intend to remove persistent application data.
- Avoid `docker compose down -v` in production unless volume deletion is intentional.
- Ensure sufficient disk space is available before loading new offline image archives.
- After deployment or upgrade, verify service status and inspect logs for startup or migration errors.
- Change default administrator passwords for OMOP Bridge, ATLAS, and Grafana immediately after the first login.
- For production deployments, use appropriate network security controls, strong credentials, backups, and TLS/HTTPS configuration.
- Never commit `.env` files containing production secrets to source control.

---

## 📄 License

Refer to the OMOP Bridge project license for licensing and usage information.