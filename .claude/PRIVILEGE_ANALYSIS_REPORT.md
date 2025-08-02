# Container Privilege Analysis Report
*Generated: 2025-08-02*

## 🔍 Executive Summary

**Critical Finding**: 57 out of 108 add-ons (53%) request SYS_ADMIN privileges - a system administration capability that grants near-root access within containers.

**Risk Assessment**: HIGH - The widespread use of SYS_ADMIN significantly increases the attack surface and potential for container escapes.

## 📊 Privilege Usage Statistics

- **Total Add-ons**: 108
- **Add-ons with Privileges**: 60 (55%)
- **SYS_ADMIN Usage**: 57 add-ons (53%)
- **NET_ADMIN Usage**: 9 add-ons (8%)
- **DAC_OVERRIDE Usage**: 0 add-ons (0%) ✅

## 🚨 Top 5 Critical Add-ons Analysis

### 1. Filebrowser (8,427 installations)
**Privileges**: `SYS_ADMIN`, `DAC_READ_SEARCH`  
**Device Access**: Extensive - All storage devices (sda-sdg, nvme, partitions)  
**Purpose**: Web-based file management interface  

**Analysis**:
- ❌ **Over-privileged**: SYS_ADMIN likely not needed for file browsing
- ❌ **Excessive device access**: Requests access to ALL possible storage devices
- ⚠️ **Security risk**: File manager with admin privileges = potential data exfiltration
- 🔧 **Alternative**: Use bind mounts with specific directories instead of SYS_ADMIN

**Justification Score**: 2/10 - Very weak justification

### 2. Nextcloud (Cloud Storage)
**Privileges**: `SYS_ADMIN`, `DAC_READ_SEARCH`  
**Device Access**: All storage and video devices  
**Purpose**: Personal cloud storage and collaboration platform  

**Analysis**:
- ⚠️ **Potentially justified**: May need filesystem operations for cloud storage
- ❌ **Excessive device access**: Duplicate device entries in config
- 🔧 **Alternative**: Use specific capabilities like `CHOWN`, `FOWNER` instead of SYS_ADMIN
- ⚠️ **Security concern**: Cloud platform with admin access to all devices

**Justification Score**: 4/10 - Weak justification, alternatives exist

### 3. Plex NAS (Media Server)
**Privileges**: `SYS_ADMIN`, `DAC_READ_SEARCH`  
**Device Access**: Storage + DVB TV tuners + video hardware  
**Purpose**: Media server with hardware transcoding  

**Analysis**:
- ⚠️ **Partially justified**: Hardware transcoding may require device access
- ❌ **SYS_ADMIN overkill**: Could use `DEVICE_CONTROL` for hardware access
- ✅ **Host networking**: Appropriate for media server discovery
- 🔧 **Alternative**: More specific device capabilities

**Justification Score**: 5/10 - Moderate justification, refinement needed

### 4. Arpspoof (Network Blocker)
**Privileges**: `SYS_ADMIN`, `DAC_READ_SEARCH`  
**Device Access**: All storage devices (unnecessary)  
**Purpose**: Block internet connection for local network devices  

**Analysis**:
- ✅ **Justified for function**: ARP spoofing requires network manipulation
- ❌ **Wrong capabilities**: Should use `NET_ADMIN` + `NET_RAW`, not SYS_ADMIN
- ❌ **Inappropriate device access**: Doesn't need storage device access
- 🔧 **Alternative**: `NET_ADMIN` + `NET_RAW` capabilities only

**Justification Score**: 3/10 - Wrong privilege type used

### 5. Radarr (Movie Management)
**Privileges**: `SYS_ADMIN`, `DAC_READ_SEARCH`  
**Device Access**: All storage devices  
**Purpose**: Movie collection management (downloads, organization)  

**Analysis**:
- ❌ **Not justified**: File management doesn't require SYS_ADMIN
- ❌ **Over-privileged**: Basic file operations don't need admin rights
- 🔧 **Alternative**: Standard file permissions with proper user mapping
- ⚠️ **Security risk**: Download manager with admin privileges

**Justification Score**: 1/10 - No justification

## 🔧 Privilege Reduction Recommendations

### Immediate Actions (Week 1)

#### 1. Filebrowser - Remove SYS_ADMIN
```json
"privileged": [
    "DAC_READ_SEARCH"  // Keep for file access
],
"devices": [
    "/dev/fuse"  // Only FUSE if needed
    // Remove all storage devices, use bind mounts instead
]
```

#### 2. Radarr/Sonarr/Bazarr - Remove SYS_ADMIN
```json
"privileged": [
    "DAC_READ_SEARCH"  // Only for reading file attributes
],
"devices": []  // Remove all device access
```

#### 3. Arpspoof - Fix Privilege Type
```json
"privileged": [
    "NET_ADMIN",      // For network manipulation
    "NET_RAW"         // For raw socket access
],
"devices": []         // Remove storage device access
```

### Medium-term Actions (Week 2-4)

#### 4. Nextcloud - Reduce Privileges
```json
"privileged": [
    "CHOWN",          // For file ownership changes
    "FOWNER",         // For file permission changes
    "DAC_READ_SEARCH" // For file access
],
// Remove duplicate device entries
```

#### 5. Plex - Specific Hardware Access
```json
"privileged": [
    "DAC_READ_SEARCH"  // For media file access
],
"devices": [
    "/dev/dri",        // GPU for transcoding
    "/dev/dvb/",       // TV tuners only
    // Remove storage devices, use bind mounts
]
```

## 📋 Category-Based Privilege Guidelines

### Media Applications (Plex, Emby, Jellyfin, Radarr, Sonarr)
**Standard Privileges**: `DAC_READ_SEARCH` only  
**Device Access**: GPU devices for transcoding only  
**Justification**: Media management requires file reading, not system administration

### File Managers (Filebrowser, Nextcloud)
**Standard Privileges**: `DAC_READ_SEARCH`, optionally `CHOWN`/`FOWNER`  
**Device Access**: None - use bind mounts  
**Justification**: File operations can be handled through proper volume mounting

### Network Tools (Arpspoof)
**Standard Privileges**: `NET_ADMIN`, `NET_RAW`  
**Device Access**: Network interfaces only  
**Justification**: Network manipulation requires network capabilities, not system admin

### Development Tools (Code-server, Gitea)
**Standard Privileges**: Minimal - consider rootless containers  
**Device Access**: None  
**Justification**: Development tools should not require elevated privileges

## 🎯 Implementation Roadmap

### Phase 1: Critical Risk Reduction (Week 1)
- [ ] Remove SYS_ADMIN from Filebrowser
- [ ] Remove SYS_ADMIN from Radarr, Sonarr, Bazarr
- [ ] Fix Arpspoof privilege types
- [ ] Test functionality with reduced privileges

### Phase 2: Systematic Review (Week 2-3)
- [ ] Review all 57 SYS_ADMIN usage instances
- [ ] Create privilege justification documentation for each
- [ ] Implement alternatives for 80% of cases

### Phase 3: Documentation & Prevention (Week 4)
- [ ] Update CONTRIBUTING.md with privilege guidelines
- [ ] Add privilege justification requirements to PR template
- [ ] Implement automated privilege checking in CI/CD

## 📈 Success Metrics

- **Target**: Reduce SYS_ADMIN usage from 57 to <15 add-ons
- **Timeline**: 4 weeks
- **Verification**: Automated testing with reduced privileges
- **Documentation**: 100% of remaining SYS_ADMIN usage documented and justified

## 🛡️ Security Impact

**Before**: 53% of add-ons with near-root container access  
**After**: <14% of add-ons with justified elevated privileges  
**Risk Reduction**: ~70% reduction in high-privilege containers  
**Attack Surface**: Significantly reduced container escape vectors

---

**Next Review**: 2025-09-02 (Monitor privilege usage trends and compliance)

*This analysis demonstrates that the majority of SYS_ADMIN usage in this repository is unnecessary and represents a significant security risk that can be mitigated through proper container security practices.*