# Security Review Checklist for Home Assistant Add-ons

## 🛡️ Pre-Submission Security Review

Use this checklist before submitting any new add-on or major changes to existing add-ons.

### ✅ Critical Security Requirements

#### File Permissions
- [ ] No `chmod 777` used anywhere in the add-on
- [ ] Scripts use `chmod 755` or `chmod +x` for executables
- [ ] Configuration files use `chmod 644` or more restrictive
- [ ] Sensitive files (keys, certs) use `chmod 600` or more restrictive

#### Container Privileges
- [ ] Add-on requests minimal required privileges only
- [ ] `privileged` array contains only necessary capabilities
- [ ] No blanket `SYS_ADMIN` unless absolutely required with justification
- [ ] Device access limited to specific devices needed
- [ ] Network access restricted to required ports/protocols

#### Script Security
- [ ] All scripts use `set -e` for error handling
- [ ] All scripts use `set -u` for undefined variable checking
- [ ] All scripts use `set -o pipefail` for pipeline error propagation
- [ ] Remote downloads include integrity verification (checksums)
- [ ] No remote script execution without verification

#### Input Validation
- [ ] All user inputs validated for format and safety
- [ ] Path inputs sanitized to prevent directory traversal
- [ ] Network inputs validated (URLs, IPs, ports)
- [ ] Configuration values have appropriate bounds checking

### 🔧 Dockerfile Security

#### Base Images
- [ ] Uses official Home Assistant base images
- [ ] Base image version is pinned (not `latest`)
- [ ] Base image is regularly updated

#### Build Process
- [ ] No secrets in build arguments or environment variables
- [ ] Build dependencies are pinned to specific versions
- [ ] Multi-stage builds used where appropriate to reduce attack surface
- [ ] Unnecessary packages removed after build

#### Runtime Security
- [ ] Non-root user used where possible
- [ ] Health checks implemented
- [ ] Proper signal handling for graceful shutdown
- [ ] Resource limits defined

### 🚪 Network Security

#### Port Configuration
- [ ] Only required ports exposed
- [ ] Internal services not exposed unnecessarily
- [ ] Ingress configuration reviewed for security
- [ ] SSL/TLS used for external communications

#### Service Discovery
- [ ] Service discovery limited to required services
- [ ] Authentication required for service access
- [ ] Service communication encrypted where sensitive

### 📁 Data Security

#### File System Access
- [ ] Read-only file system where possible
- [ ] Temporary files in appropriate directories
- [ ] Sensitive data not logged
- [ ] File permissions set appropriately on mounted volumes

#### Configuration Management
- [ ] Sensitive configuration values use Home Assistant secrets
- [ ] Default configurations are secure
- [ ] Configuration validation prevents dangerous settings
- [ ] Configuration files not world-readable

### 🔍 Code Quality

#### Error Handling
- [ ] Graceful error handling implemented
- [ ] Error messages don't leak sensitive information
- [ ] Appropriate logging levels used
- [ ] Failed operations don't leave system in unsafe state

#### Dependencies
- [ ] All dependencies are from trusted sources
- [ ] Dependencies are pinned to specific versions
- [ ] Vulnerability scanning performed on dependencies
- [ ] Unused dependencies removed

### 📋 AppArmor Profile

#### Profile Completeness
- [ ] AppArmor profile exists and is tested
- [ ] Profile follows principle of least privilege
- [ ] No blanket capability grants without justification
- [ ] File access restrictions appropriate
- [ ] Network access restrictions defined

#### Profile Testing
- [ ] Profile tested with add-on functionality
- [ ] Profile doesn't break legitimate operations
- [ ] Profile logs violations for monitoring
- [ ] Profile updated when add-on functionality changes

### 📚 Documentation

#### Security Documentation
- [ ] Security considerations documented in README
- [ ] Required privileges explained and justified
- [ ] Known security limitations documented
- [ ] Upgrade/migration security notes provided

#### Configuration Documentation
- [ ] Security-relevant configuration options explained
- [ ] Default security settings documented
- [ ] Best practices for secure configuration provided
- [ ] Examples show secure configurations

### 🧪 Testing

#### Security Testing
- [ ] Add-on tested with minimal privileges
- [ ] Input validation tested with malicious inputs
- [ ] Error conditions tested for security implications
- [ ] Integration testing performed with Home Assistant security features

#### Automated Testing
- [ ] Security linting passes (shellcheck, hadolint, etc.)
- [ ] Dependency vulnerability scanning passes
- [ ] Container image scanning passes
- [ ] Configuration validation testing passes

## 🚨 Red Flags - Automatic Review Required

The following items require mandatory security team review:

- [ ] `chmod 777` anywhere in the code
- [ ] `SYS_ADMIN` or `DAC_OVERRIDE` capabilities
- [ ] Network host mode requested
- [ ] Privileged container mode requested
- [ ] Direct hardware device access
- [ ] Custom AppArmor profile bypass
- [ ] Remote code execution capabilities
- [ ] Cryptographic key generation or storage
- [ ] User authentication mechanisms
- [ ] File system modifications outside add-on directories

## 📝 Review Sign-off

### Reviewer Information
- **Reviewer Name**: ________________
- **Review Date**: ________________  
- **Add-on Name**: ________________
- **Add-on Version**: ________________

### Security Assessment
- **Risk Level**: [ ] Low [ ] Medium [ ] High [ ] Critical
- **Approval Status**: [ ] Approved [ ] Conditionally Approved [ ] Rejected

### Required Actions (if any)
1. _________________________________
2. _________________________________
3. _________________________________

### Final Approval
- [ ] All critical security requirements met
- [ ] All red flags addressed or justified
- [ ] Security documentation complete
- [ ] Testing completed successfully

**Reviewer Signature**: ________________ **Date**: ________________

---

*This checklist should be completed for every new add-on and major security-related changes to existing add-ons. Keep this document updated as security requirements evolve.*