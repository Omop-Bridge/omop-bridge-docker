# OMOP Bridge — Deployment and Upgrade Guide

This guide explains how to deploy, operate, upgrade, and troubleshoot **OMOP Bridge** using online container registries and Docker Compose.

## 📋 Table of Contents

1. [Cloning and Fetching Large Files](#-cloning-and-fetching-large-files)
2. [Deployment Steps](#-deployment-steps)
3. [Lifecycle Management Scripts](#%EF%B8%8F-lifecycle-management-scripts)
4. [Accessing OMOP Bridge and Services](#-accessing-omop-bridge-and-services)
5. [Default Login Credentials](#-default-login-credentials)
6. [Data Persistence](#-data-persistence)
7. [Troubleshooting and Verification](#-troubleshooting-and-verification)
8. [Typical Deployment Structure](#-typical-deployment-structure)
9. [Quick Reference](#-quick-reference)
10. [Important Operational Notes](#-important-operational-notes)
11. [License](#-license)

---

## 📥 Cloning and Fetching Large Files

OMOP Bridge utilizes Git LFS (Large File Storage) to manage large binary assets.

### 1. Clone the Repository

Always use `git clone` to acquire the project repository. **Do not use GitHub's "Download ZIP" option**, as ZIP downloads omit the `.git` directory and substitute LFS binaries with tiny text pointer files, causing initialization and database imports to fail.

```bash
git clone https://github.com/Omop-Bridge/omop-bridge-docker.git
cd omop-bridge-docker
```

### 2. Pull Large Files via Git LFS

Ensure Git LFS is installed on your system, then pull the required binary files into your local directory:

```bash
git lfs install
git lfs pull
```

---

## 🚀 Deployment Steps

### Prerequisites

Before deploying OMOP Bridge, ensure that:

- Docker Engine is installed and running.
- Docker Compose is available.
- Container registries are accessible.
- A properly configured `.env` file exists in the project root.

### 1. Navigate to the Project Root

```bash
cd omop-bridge-docker
```

### 2. Download and Place OMOP Vocabularies

Download your customized OMOP vocabulary export package (ZIP file) from [Athena (OHDSI)](https://athena.ohdsi.org/), and place the downloaded ZIP file directly into the project's `db/athena_data/` folder before starting the server.

```bash
# Example directory placement check
ls -lh db/athena_data/
```

### 3. Configure the `.env` File

OMOP Bridge includes a sample environment configuration file named `.env.sample`.

Create your deployment-specific `.env` file and generate a secure JWT secret:

```bash
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

### 4. Start the Stack

Make the lifecycle script executable and start the OMOP Bridge stack:

```bash
chmod +x scripts/start.sh scripts/upgrade.sh scripts/stop.sh scripts/destroy.sh 
./scripts/start.sh
```

The startup script builds the required containers, starts the services in detached mode, provides progress feedback, and tails database initialization logs.

### 5. Verify the Deployment

Check the status of all services:

```bash
docker compose ps
```

All expected services should show a status such as **running** or **healthy**.

---

## 🛠️ Lifecycle Management Scripts

OMOP Bridge includes helper scripts in the `scripts/` directory to simplify common operational tasks.

### Start Stack

**Script:** `scripts/start.sh`

Builds container images, starts the stack in detached mode, and monitors database initialization logs.

```bash
./scripts/start.sh
```

### Stop Stack

**Script:** `scripts/stop.sh`

Gracefully stops the running services without deleting persistent Docker volumes or application data.

```bash
./scripts/stop.sh
```

### Upgrade Stack

**Script:** `scripts/upgrade.sh`

Pulls the latest base images, rebuilds the containers, restarts the stack, and tails database logs to help verify the upgrade.

```bash
./scripts/upgrade.sh
```

> **Recommendation:** Always back up critical production data and review release notes before performing an upgrade.

### Destroy Stack

**Script:** `scripts/destroy.sh`

> ⚠️ **WARNING:** This operation tears down the containers **and removes persistent volumes**, including database data.

Use this script only when you intentionally want to perform a complete factory reset.

```bash
./scripts/destroy.sh
```

---

## 🌐 Accessing OMOP Bridge and Services

Once the deployment stack is successfully running, the core application and supporting services can be accessed through a web browser.

| Service | Access URL |
| :--- | :--- |
| **OMOP Bridge Main App** | `http://localhost` |
| **ATLAS Analytics** | `http://localhost/atlas/` |
| **Grafana Dashboards** | `http://localhost/grafana` |
| **Database Manager (DbGate)** | `http://localhost/db/` |

For remote deployments, replace `localhost` with the server's hostname, domain name, or IP address (e.g., `http://your-server-hostname`).

---

## 🔑 Default Login Credentials

The following default administrator credentials are provided for initial access:

| Service | Username | Password |
| :--- | :--- | :--- |
| **OMOP Bridge** | `admin@omopbridge.com` | `admin` |
| **ATLAS Analytics** | `admin` | `admin` |
| **Grafana Monitoring** | `admin` | `admin` |

> ⚠️ **Security Note:** Change all default administrator passwords immediately after the initial login, especially in production environments.

---

## 💾 Data Persistence

OMOP Bridge uses Docker volumes to persist important application and database state independently of container lifecycles.

The primary persistent volumes include:

- `omopbridge_db_data`
- `atlas3-webapi-data`
- `dqd_results`

Stopping, restarting, rebuilding, or upgrading containers does not normally remove data stored in these volumes.

### ⚠️ Important Volume Warning

Do **not** run the following command unless you intentionally want to remove all persistent Docker volumes:

```bash
docker compose down -v
```

The `-v` option removes the associated volumes and can result in permanent data loss.

---

## 🔍 Troubleshooting and Verification

### Check Running Containers

Display the status of all Docker Compose services:

```bash
docker compose ps
```

### View Logs for All Services

Follow logs from all services:

```bash
docker compose logs -f
```

### View Logs for a Specific Service

Backend logs:
```bash
docker compose logs -f backend
```

Database logs:
```bash
docker compose logs -f omop-bridge-db
```

### Check Docker Volumes

List available Docker volumes:

```bash
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

---

## 📦 Typical Deployment Structure

A typical OMOP Bridge Docker deployment has the following structure:

```text
omop-bridge-docker/
├── docker-compose.yml
├── .env
├── .env.sample
├── db/
│   └── athena_data/   <-- Place Athena vocab zip here
└── scripts/
    ├── start.sh
    ├── stop.sh
    ├── upgrade.sh
    └── destroy.sh
```

### File and Directory Overview

| Path | Purpose |
| :--- | :--- |
| `docker-compose.yml` | Defines the OMOP Bridge services and deployment configuration |
| `db/athena_data/` | Directory where downloaded Athena vocabulary ZIP files are placed |
| `.env` | Deployment-specific environment variables and configuration |
| `.env.sample` | Template containing example environment variables |
| `scripts/start.sh` | Starts and initializes the stack |
| `scripts/stop.sh` | Stops the stack without removing persistent data |
| `scripts/upgrade.sh` | Updates images and restarts the stack |
| `scripts/destroy.sh` | Completely removes the stack and persistent volumes |

---

## 📌 Quick Reference

| Task | Command |
| :--- | :--- |
| **Start stack & monitor logs** | `./scripts/start.sh` |
| **Stop stack** | `./scripts/stop.sh` |
| **Upgrade stack** | `./scripts/upgrade.sh` |
| **Destroy stack & data** | `./scripts/destroy.sh` |
| **Check services** | `docker compose ps` |
| **View all logs** | `docker compose logs -f` |
| **View database logs** | `docker compose logs -f omop-bridge-db` |
| **List Docker volumes** | `docker volume ls` |

---

## 📌 Important Operational Notes

- Download your vocabulary ZIP file from Athena and place it under `db/athena_data/` before starting the server.
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

---

## 📄 License

Refer to the OMOP Bridge project license for licensing and usage information.