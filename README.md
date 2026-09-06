# OMOP Bridge — Deployment and Upgrade Guide

This guide explains how to deploy, operate, upgrade, and troubleshoot **OMOP Bridge** using online container registries and Docker Compose.

## 📋 Table of Contents

1. [Cloning and Fetching Large Files](https://www.google.com/search?q=%23-cloning-and-fetching-large-files)
2. [Deployment Steps](https://www.google.com/search?q=%23-deployment-steps)
3. [Lifecycle Management Scripts](https://www.google.com/search?q=%23%EF%B8%8F-lifecycle-management-scripts)
4. [Accessing OMOP Bridge and Services](https://www.google.com/search?q=%23-accessing-omop-bridge-and-services)
5. [Default Login Credentials](https://www.google.com/search?q=%23-default-login-credentials)
6. [Data Persistence](https://www.google.com/search?q=%23-data-persistence)
7. [Troubleshooting and Verification](https://www.google.com/search?q=%23-troubleshooting-and-verification)
8. [Typical Deployment Structure](https://www.google.com/search?q=%23-typical-deployment-structure)
9. [Quick Reference](https://www.google.com/search?q=%23-quick-reference)
10. [Important Operational Notes](https://www.google.com/search?q=%23-important-operational-notes)
11. [License](https://www.google.com/search?q=%23-license)

## 📥 Cloning and Fetching Large Files

OMOP Bridge utilizes Git LFS (Large File Storage) to manage large binary assets.

### 1. Clone the Repository

Always use `git clone` to acquire the project repository. **Do not use GitHub's "Download ZIP" option**, as ZIP downloads omit the `.git` directory and substitute LFS binaries with tiny text pointer files, causing initialization and database imports to fail.

Bash

```
git clone https://github.com/your-username/omop-bridge-docker.git
cd omop-bridge-docker

```

### 2. Pull Large Files via Git LFS

Ensure Git LFS is installed on your system, then pull the required binary files into your local directory:

Bash

```
git lfs install
git lfs pull

```

### 3. Verify File Integrity

Confirm that the large database archive has successfully downloaded and is at its full expected size 880MB (rather than a few bytes) before launching the stack:

Bash

```
ls -lh db/omop_vocab_baseline.sql.gz

```

## 🚀 Deployment Steps

### Prerequisites

Before deploying OMOP Bridge, ensure that:

- Docker Engine is installed and running.
- Docker Compose is available.
- Container registries are accessible.
- A properly configured `.env` file exists in the project root.

### 1. Navigate to the Project Root

Bash

```
cd omop-bridge-docker

```

### 2. Configure the `.env` File

OMOP Bridge includes a sample environment configuration file named `.env.sample`.

Create your deployment-specific `.env` file and generate a secure JWT secret:

Bash

```
cp .env.sample .env && \
sed -i "s/JWT_SECRET_KEY=.*/JWT_SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(32))')/g" .env

```

Review and update `.env` with the appropriate:

- Database credentials
- Service configuration
- Application settings
- API configuration
- Security settings

> **Important:** Never commit production credentials, API keys, JWT secrets, or other sensitive values to source control.

### 3. Start the Stack

Make the lifecycle script executable and start the OMOP Bridge stack:

Bash

```
chmod +x scripts/start.sh scripts/upgrade.sh scripts/stop.sh scripts/destroy.sh 
./scripts/start.sh

```

The startup script builds the required containers, starts the services in detached mode, provides progress feedback, and tails database initialization logs.

### 4. Verify the Deployment

Check the status of all services:

Bash

```
docker compose ps

```

All expected services should show a status such as **running** or **healthy**.

## 🛠️ Lifecycle Management Scripts

OMOP Bridge includes helper scripts in the `scripts/` directory to simplify common operational tasks.

### Start Stack

**Script:** `scripts/start.sh`

Builds container images, starts the stack in detached mode, and monitors database initialization logs.

Bash

```
./scripts/start.sh

```

### Stop Stack

**Script:** `scripts/stop.sh`

Gracefully stops the running services without deleting persistent Docker volumes or application data.

Bash

```
./scripts/stop.sh

```

### Upgrade Stack

**Script:** `scripts/upgrade.sh`

Pulls the latest base images, rebuilds the containers, restarts the stack, and tails database logs to help verify the upgrade.

Bash

```
./scripts/upgrade.sh

```

> **Recommendation:** Always back up critical production data and review release notes before performing an upgrade.

### Destroy Stack

**Script:** `scripts/destroy.sh`

> ⚠️ **WARNING:** This operation tears down the containers **and removes persistent volumes**, including database data.

Use this script only when you intentionally want to perform a complete factory reset.

Bash

```
./scripts/destroy.sh

```

## 🌐 Accessing OMOP Bridge and Services

Once the deployment stack is successfully running, the core application and supporting services can be accessed through a web browser.

| **Service**                   | **Access URL**             |
| ----------------------------- | -------------------------- |
| **OMOP Bridge Main App**      | `http://localhost`         |
| **ATLAS Analytics**           | `http://localhost/atlas/`  |
| **Grafana Dashboards**        | `http://localhost/grafana` |
| **Database Manager (DbGate)** | `http://localhost/db/`     |

For remote deployments, replace `localhost` with the server's hostname, domain name, or IP address.

For example:

Plaintext

```
http://your-server-hostname

```

## 🔑 Default Login Credentials

The following default administrator credentials are provided for initial access:

| **Service**            | **Username**           | **Password** |
| ---------------------- | ---------------------- | ------------ |
| **OMOP Bridge**        | `admin@omopbridge.org` | `admin`      |
| **ATLAS Analytics**    | `admin`                | `admin`      |
| **Grafana Monitoring** | `admin`                | `admin`      |

> ⚠️ **Security Note:** Change all default administrator passwords immediately after the initial login, especially in production environments.

## 💾 Data Persistence

OMOP Bridge uses Docker volumes to persist important application and database state independently of container lifecycles.

The primary persistent volumes include:

- `omopbridge_db_data`
- `atlas3-webapi-data`
- `dqd_results`

Stopping, restarting, rebuilding, or upgrading containers does not normally remove data stored in these volumes.

### ⚠️ Important Volume Warning

Do **not** run the following command unless you intentionally want to remove all persistent Docker volumes:

Bash

```
docker compose down -v

```

The `-v` option removes the associated volumes and can result in permanent data loss.

## 🔍 Troubleshooting and Verification

### Check Running Containers

Display the status of all Docker Compose services:

Bash

```
docker compose ps

```

### View Logs for All Services

Follow logs from all services:

Bash

```
docker compose logs -f

```

### View Logs for a Specific Service

Backend logs:

Bash

```
docker compose logs -f backend

```

Database logs:

Bash

```
docker compose logs -f omop-bridge-db

```

### Check Docker Volumes

List available Docker volumes:

Bash

```
docker volume ls

```

### Basic Deployment Verification

After starting or upgrading the stack, verify that:

1. All expected containers are running.
2. Services report a healthy status where health checks are configured.
3. The OMOP Bridge web interface is accessible.
4. ATLAS is accessible.
5. Grafana is accessible.
6. DbGate is accessible.
7. Database initialization has completed successfully.
8. No persistent-volume errors appear in the logs.

## 📦 Typical Deployment Structure

A typical OMOP Bridge Docker deployment has the following structure:

Plaintext

```
omop-bridge-docker/
├── docker-compose.yml
├── .env
├── .env.sample
└── scripts/
    ├── start.sh
    ├── stop.sh
    ├── upgrade.sh
    └── destroy.sh

```

### File and Directory Overview

| **Path**             | **Purpose**                                                   |
| -------------------- | ------------------------------------------------------------- |
| `docker-compose.yml` | Defines the OMOP Bridge services and deployment configuration |
| `.env`               | Deployment-specific environment variables and configuration   |
| `.env.sample`        | Template containing example environment variables             |
| `scripts/start.sh`   | Starts and initializes the stack                              |
| `scripts/stop.sh`    | Stops the stack without removing persistent data              |
| `scripts/upgrade.sh` | Updates images and restarts the stack                         |
| `scripts/destroy.sh` | Completely removes the stack and persistent volumes           |

## 📌 Quick Reference

| **Task**                   | **Command**                             |
| -------------------------- | --------------------------------------- |
| Start stack & monitor logs | `./scripts/start.sh`                    |
| Stop stack                 | `./scripts/stop.sh`                     |
| Upgrade stack              | `./scripts/upgrade.sh`                  |
| Destroy stack & data       | `./scripts/destroy.sh`                  |
| Check services             | `docker compose ps`                     |
| View all logs              | `docker compose logs -f`                |
| View database logs         | `docker compose logs -f omop-bridge-db` |
| List Docker volumes        | `docker volume ls`                      |

## 📌 Important Operational Notes

- Always back up critical production data before performing major upgrades.
- Review release notes before upgrading.
- Verify that the `.env` file is compatible with the new release.
- Compare the current `.env` with the latest `.env.sample` when upgrading.
- Do not delete Docker volumes unless you explicitly intend to remove persistent application data.
- Avoid `docker compose down -v` in production unless volume deletion is intentional.
- Ensure sufficient disk space is available before rebuilding containers.
- Change all default administrator passwords immediately after the first login.
- Never commit `.env` files containing production secrets to source control.
- Ensure container registries are reachable before starting or upgrading the stack.
- Verify service health after every deployment or upgrade.
- Back up the database before major version upgrades or migrations.

## 📄 License

Refer to the OMOP Bridge project license for licensing and usage information.