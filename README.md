# 🚀 High Availability Hadoop Ecosystem with HBase & Hive

This project sets up a production-grade **Hadoop ecosystem** using Docker Compose with High Availability (HA) for **HDFS**, **YARN**, **HBase**, and **Hive**, coordinated via **ZooKeeper** and backed by **PostgreSQL** for Hive Metastore.

---

## 📦 Components Overview

| Component         | Count | Description |
|------------------|-------|-------------|
| **Hadoop NameNodes (HA)** | 3 | High-availability NameNodes with JournalNodes |
| **YARN ResourceManager** | 3 | HA Resource Managers embedded in master nodes |
| **DataNodes & NodeManagers** | 2 | Workers running DataNode & NodeManager |
| **ZooKeeper Ensemble** | 3 | One per master node for quorum management |
| **HBase Master (HA)** | 2 | Active-Standby configuration |
| **HBase RegionServers** | 2 | Storage engine for HBase |
| **Hive Metastore** | 1 | Backed by PostgreSQL |
| **HiveServer2** | 1 | Query engine for Hive |
| **PostgreSQL** | 1 | Metastore DB for Hive |

---

## 🗂️ Folder Structure

```
.
├── Dockerfile               # Multi-stage build for Hadoop, Hive, and HBase
├── docker-compose.yaml      # Multi-container cluster orchestration
├── start-hadoop.sh          # Entrypoint script for Hadoop services
├── start-hbase.sh           # Entrypoint script for HBase services
├── start-hive.sh            # Entrypoint script for Hive services
```

---

## 🛠️ Setup Instructions

### 1. 🚧 Build & Start Cluster

```bash
docker-compose build
docker-compose up -d
```

Ensure all services pass their health checks.

### 2. 📊 Access Web UIs

| Service           | URL                        |
|------------------|----------------------------|
| **HDFS UI (NN1)**    | http://localhost:9878     |
| **YARN UI**          | http://localhost:8888     |
| **HiveServer2 (JDBC)** | jdbc:hive2://localhost:10000 |
| **HBase UI (HM1)**   | http://localhost:16010    |

---

## 📍 Service Roles

### 🧠 Master Nodes
- Host **NameNode**, **ResourceManager**, and **ZooKeeper**
- JournalNode volumes for HA HDFS

### 🔧 Worker Nodes
- Run **DataNode** and **NodeManager**
- Depend on all three master nodes

### 🐝 HBase
- 2 Masters (HA)
- 2 RegionServers with HDFS-backed volumes

### 🐘 Hive
- **Metastore** connected to PostgreSQL
- **HiveServer2** handles queries
- Runs only after master & metastore are healthy

---

## 📄 Health Checks

Each major service (HDFS, Hive, PostgreSQL, HBase) uses Docker `healthcheck` to ensure container health before others depend on it.

---

## 🔐 Network & Volumes

- **Network**: All containers connected through `hadoopnet` bridge
- **Volumes**: Separate persistent volumes per component

---

## 🔄 Cleanup

```bash
docker-compose down -v
```

This will stop and remove all containers and volumes.

---

## 📌 Notes

- Ensure your system has enough resources: recommended 8+ GB RAM and 4+ CPUs
- For production, use external persistent storage and real domain names/IPs

---

## 🙌 Authors

**Designed & Engineered by**: Mohamed Moaaz
Inspired by scalable Hadoop deployments for modern data platforms.
