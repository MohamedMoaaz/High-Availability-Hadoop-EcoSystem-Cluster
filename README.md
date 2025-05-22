# 🚀 HBase High Availability Cluster with Hadoop on Docker 🐳

## 🌟 Project Overview

This project implements a **highly available HBase cluster** on Docker containers, integrating **Hadoop HA** with multiple Namenodes, **ZooKeeper quorum**, and **HBase master HA**. It's like building a distributed superhero team where if one member falls, another instantly takes over! 💪

**Key Features:**
- 🛡️ Fault-tolerant architecture
- 🔄 Automatic failover
- ⚖️ Load balancing
- 🐘 Scalable distributed storage

---

## 🏗️ Architecture and Components

### 🐘 Hadoop HA Setup
- **3 Namenodes** in HA mode (`master1`, `master2`, `master3`) - because one master is never enough!
- **ZooKeeper quorum** for coordination (the wise council of the cluster)
- **JournalNodes** for shared edit logs (like a shared diary for the cluster)
- **HDFS DataNodes** running alongside RegionServers (double agents!)

### 🅱️ HBase HA Setup
- **2 HBase Masters** (`hmaster1`, `hmaster2`) in active/standby mode (always ready to jump in)
- **2 RegionServers** (`regionserver1`, `regionserver2`) - the hard workers storing all your data
- **ZooKeeper** as the backbone (the puppet master behind the scenes)

---

## 🐳 Docker Compose Configuration

Our `docker-compose.yaml` is the magic recipe that brings everything together:

```yaml
services:
  master1, master2, master3: � Hadoop Namenodes with HA configuration
  hmaster1, hmaster2: 👑 HBase Master nodes
  regionserver1, regionserver2: 💪 HBase RegionServers (also Hadoop DataNodes)

## 🔑 Key Ingredients

### 📦 Storage & Networking
- **Persistent volumes** for ZooKeeper, HDFS, and HBase data
- **Dedicated hadoopnet network** for smooth inter-service communication

### 🩺 Reliability Features
- **Health checks** to ensure proper startup order and service availability
```
### ⚙️ Configuration Files
#### 📄 hbase-site.xml (The Brain of HBase)
Configures all critical operations including:
- 🎯 High Availability masters setup
- 🦥 ZooKeeper quorum configuration
- 📂 Data directories location
- ⚖️ Load balancer settings for optimal performance
### ⚙️ Configuration Files (Continued)

#### 📄 zoo.cfg (ZooKeeper's Rulebook)
Defines the coordination rules for the cluster:
- � **Ensemble servers** - The team players in the quorum
- 🔌 **Port configurations** - Communication endpoints

#### 🐋 Dockerfile (Container Blueprint)
The foundation for building our images with:
- 🧩 **Necessary binaries** - All required software components
- ⚙️ **Custom configurations** - Tailored settings for our cluster

#### 🚀 start-hbase.sh (Cluster Ignition)
The launch sequence script that:
- Initializes HBase daemons with proper **environment variables**
- Ensures smooth startup of all components
## ⚙️ Configuration Magic 

### 📜 Core Configuration Files

#### 📄 zoo.cfg (ZooKeeper's Command Center)
The rulebook that keeps your ensemble in sync:
- � **Server Ensemble** - Lists all ZK nodes in the quorum
- 🔌 **Port Mapping** - 2181 for clients, 2888 for peers, 3888 for elections
- ⏱️ **Timeouts** - Tune for your network environment

#### 🐋 Dockerfile (Container Architect)
The blueprint that builds our superhero containers:
```dockerfile
FROM hadoop-hbase-base
🧩 Installs:
  - OpenJDK 8
  - Hadoop 3.x 
  - HBase 2.x
  - ZooKeeper 3.6
⚙️ Applies:
  - Custom XML configs
  - Security policies
  - Performance tweaks
```
## 🛠️ Setup and Deployment

### 📋 Prerequisites

Before launching your cluster, ensure you have:

- 🐳 **Docker & Docker Compose**  
  ```bash
  # Verify installation
  docker --version && docker-compose --version

## 🎯 Validating High Availability

### 🎭 Master Failover Test
Prove your cluster's resilience by simulating a master failure:

```bash
# 1. Terminate the active HBase Master (cold-blooded!)
docker exec -it hmaster1 bash -c "kill -9 \$(jps | grep HMaster | awk '{print \$1}')"

# 2. Watch the standby take over (like a superhero sidekick!)
watch -n 1 'docker exec hmaster2 bash -c "echo \\\"status 'detailed'\\\" | hbase shell"'
```
## ⚖️ Load Balancing Magic

### 🔀 Triggering Cluster Rebalancing
Activate HBase's built-in balancer to evenly distribute regions across servers:

```bash
# Enter the HBase shell
hbase shell

# Enable the balancer (if not already active)
> balance_switch true
🚦 "Balancer is now: true"

# Manually trigger rebalancing
> balance
🌀 "Balancer ran successfully" (returns true)

# Monitor progress (in another terminal)
watch -n 1 'docker exec regionserver1 hbase hbck -details'
```

What Happens Next:

HBase's balancer thread wakes up (default: every 5 mins)

It calculates the cost of current region distribution

Proposes optimal region movements (following rules):

🔀 Max 1 region move per RegionServer at a time

⏳ Respects hbase.balancer.max.balancing (default: 2hr runtime)

🚫 Never moves meta/system tables

Pro Tip:
For immediate rebalancing during maintenance:
### Force rapid successive balances (careful with production!)

for i in {1..3}; do 
  echo "balance" | hbase shell
  sleep 30
done

## 🔍 Maintenance and Monitoring

### 🛠️ Pro Tips
- **📜 Log Inspection**  
  ```bash
  # Tail HBase logs
  docker exec -it hmaster1 tail -f /usr/local/hbase/logs/hbase--master-$(hostname).log
  
  # Check Hadoop logs
  docker exec -it master1 tail -f /usr/local/hadoop/logs/hadoop--namenode-$(hostname).log
🌐 Web UIs for Health Checks

Service	Default Port	Path
HBase Master	16010	/master-status
HDFS Namenode	9870	/dfshealth.html
RegionServers	16030	/rs-status

🚨 Troubleshooting Guide
🩹 Common Issues and Fixes
Symptom	Likely Cause	Solution
HBase master won't activate	ZooKeeper connectivity	docker-compose logs zookeeper1
Components failing to start	Hadoop services down	Verify Namenode/JournalNode logs
Port conflicts	Docker mapping overlaps	netstat -tulnp | grep <port>
Configuration errors	XML file syntax	xmllint --format hbase-site.xml
📚 Essential References
📖 Apache HBase Reference Guide

🦉 Hadoop HA Architecture Guide

🔮 ZooKeeper Admin Guide

🐳 Docker Networking Docs
