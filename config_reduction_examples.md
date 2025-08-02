# Container Privilege Reduction Examples

## 🔧 Practical Examples for Immediate Implementation

This document provides specific configuration changes to reduce container privileges in the top add-ons.

### 1. Filebrowser - Remove Excessive Privileges

**Current Configuration** (High Risk):
```json
{
  "privileged": ["SYS_ADMIN", "DAC_READ_SEARCH"],
  "devices": [
    "/dev/dri", "/dev/dri/card0", "/dev/dri/card1",
    "/dev/sda", "/dev/sdb", "/dev/sdc", "/dev/sdd",
    "/dev/nvme", "/dev/nvme0", "/dev/nvme0n1",
    "...70+ device entries..."
  ]
}
```

**Recommended Configuration** (Secure):
```json
{
  "privileged": ["DAC_READ_SEARCH"],
  "devices": [
    "/dev/fuse"  // Only if FUSE filesystems needed
  ]
}
```

**Rationale**: File browsing doesn't require system administration privileges. Use proper volume mounting instead of device access.

### 2. Radarr/Sonarr/Bazarr - Media Management

**Current Configuration** (High Risk):
```json
{
  "privileged": ["SYS_ADMIN", "DAC_READ_SEARCH"],
  "devices": ["All storage devices..."]
}
```

**Recommended Configuration** (Secure):
```json
{
  "privileged": ["DAC_READ_SEARCH"],
  "devices": []
}
```

**Rationale**: Media collection management is file I/O operations that don't require admin privileges.

### 3. Arpspoof - Network Blocking Tool

**Current Configuration** (Wrong Privileges):
```json
{
  "privileged": ["SYS_ADMIN", "DAC_READ_SEARCH"],
  "devices": ["All storage devices..."]
}
```

**Recommended Configuration** (Correct Privileges):
```json
{
  "privileged": ["NET_ADMIN", "NET_RAW"],
  "devices": [],
  "host_network": true
}
```

**Rationale**: ARP spoofing requires network manipulation capabilities, not system administration. No storage access needed.

### 4. Nextcloud - Cloud Storage

**Current Configuration** (Over-privileged):
```json
{
  "privileged": ["SYS_ADMIN", "DAC_READ_SEARCH"],
  "devices": ["Duplicate and excessive device entries..."]
}
```

**Recommended Configuration** (Minimal):
```json
{
  "privileged": ["CHOWN", "FOWNER", "DAC_READ_SEARCH"],
  "devices": [
    "/dev/fuse"  // For external storage mounting
  ]
}
```

**Rationale**: Cloud storage needs file ownership management, not full system administration.

### 5. Plex - Media Server

**Current Configuration** (Over-privileged):
```json
{
  "privileged": ["SYS_ADMIN", "DAC_READ_SEARCH"],
  "devices": ["Storage + Video + DVB devices..."]
}
```

**Recommended Configuration** (Hardware-specific):
```json
{
  "privileged": ["DAC_READ_SEARCH"],
  "devices": [
    "/dev/dri", "/dev/dri/card0", "/dev/dri/renderD128",  // GPU transcoding
    "/dev/dvb/adapter*/demux*", "/dev/dvb/adapter*/dvr*"  // TV tuners only
  ]
}
```

**Rationale**: Media server needs GPU access for transcoding and TV tuner access, but not system administration.

## 🏗️ Implementation Templates

### Template A: File Management Applications
```json
{
  "privileged": ["DAC_READ_SEARCH"],
  "devices": [],
  "map": [
    "media:rw",
    "share:rw", 
    "addon_config:rw"
  ]
}
```
**Use for**: Filebrowser, file managers, backup tools

### Template B: Media Applications  
```json
{
  "privileged": ["DAC_READ_SEARCH"],
  "devices": [
    "/dev/dri",           // GPU transcoding only
    "/dev/dri/card0",
    "/dev/dri/renderD128"
  ],
  "map": [
    "media:rw",
    "share:rw"
  ]
}
```
**Use for**: Plex, Emby, Jellyfin, Radarr, Sonarr

### Template C: Network Applications
```json
{
  "privileged": ["NET_ADMIN", "NET_RAW"],
  "devices": [],
  "host_network": true
}
```
**Use for**: Network monitoring, VPN, proxy tools

### Template D: Database Applications
```json
{
  "privileged": [],
  "devices": [],
  "map": [
    "addon_config:rw"
  ]
}
```
**Use for**: PostgreSQL, MariaDB, Redis

## 📋 Validation Checklist

Before implementing privilege reduction:

- [ ] **Test functionality** with reduced privileges in development
- [ ] **Document breaking changes** in upgrade notes
- [ ] **Provide migration guide** for users
- [ ] **Update AppArmor profiles** to match new privilege set
- [ ] **Verify device access** is still functional where needed

## ⚠️ Breaking Changes Notice

**Important**: These privilege reductions may require users to:

1. **Restart add-ons** after configuration update
2. **Reconfigure external storage** for file managers
3. **Update file permissions** manually in some cases
4. **Check hardware transcoding** still works for media servers

## 🧪 Testing Approach

1. **Create test branch** with privilege reductions
2. **Test core functionality** of each affected add-on
3. **Verify security** with reduced privileges
4. **Document any issues** and create mitigation steps
5. **Rollback plan** if critical functionality breaks

---

*These examples provide a practical roadmap for implementing the security improvements identified in the privilege analysis.*