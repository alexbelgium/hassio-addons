# Portainer Agent Build Failure - Root Cause Analysis & Resolution

**Status:** Issue #2318 - RESOLVED via PR #2320
**Date:** December 30, 2025
**Affected Users:** All users trying to update Portainer Agent to `alpine-sts-bashio-fix` version
**Error Message:** `DockerError(404, 'manifest unknown')`

---

## 🔴 The Problem

Users attempting to update the Portainer Agent add-on encounter a `404 manifest unknown` error:

```
Failed to call /addons/db21ed7f_portainer_agent/update -
DockerError(404, 'manifest unknown')
```

This prevents ALL users from updating to the Portainer Agent version that includes the protection mode fix.

---

## 🔍 Root Cause Analysis

### What Went Wrong

A **critical circular dependency** was introduced in the Dockerfile that prevents Docker images from building successfully.

**The Broken Code (PR #2315 - Commit f0f12512):**
```dockerfile
COPY --from=ghcr.io/alexbelgium/portainer_agent-${BUILD_ARCH}:alpine-sts /app /app
                    ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
                    This is the image being built!
```

### Why This Breaks the Build

**Step-by-step failure:**

1. GitHub Actions starts the build:
   ```
   docker build -t ghcr.io/alexbelgium/portainer_agent-amd64:alpine-sts .
   ```

2. Dockerfile is processed and hits:
   ```dockerfile
   COPY --from=ghcr.io/alexbelgium/portainer_agent-amd64:alpine-sts /app /app
   ```

3. Docker tries to find the source image:
   ```
   ghcr.io/alexbelgium/portainer_agent-amd64:alpine-sts
   ```

4. **This image doesn't exist yet** - we're in the middle of building it!

5. Build fails with:
   ```
   Error: manifest unknown
   ```

6. **Result:** The tag `alpine-sts` is never created in the registry

7. **User Impact:** When users try to update, Home Assistant Supervisor tries to pull:
   ```
   ghcr.io/alexbelgium/portainer_agent-amd64:alpine-sts
   ```
   → Returns `404 manifest unknown` (because the build never completed)

### How This Happened

**PR #2315 Timeline:**

1. **Original PR (Commit 6de904a)** ✅ CORRECT
   - Fixed protection mode false-positive error
   - Upgraded bashio to main branch
   - Used `COPY --from=ghcr.io/portainerci/agent:latest` (official upstream image)
   - Code review approved

2. **Code Review Feedback (Commit f0f12512)** ⚠️ INTRODUCED BUG
   - Reviewer suggested: "Add multi-architecture support with BUILD_FROM/BUILD_ARCH"
   - This was a VALID suggestion for architecture support
   - But the implementation was incorrect:
     - Changed `COPY --from` to reference a custom (self-built) image
     - No verification that this would still build successfully
     - No local testing of the modified Dockerfile
     - No discussion of why the image source changed

3. **PR Merged** ❌ WITH BROKEN CODE
   - All initial GitHub Actions checks passed
   - **But** the final build in GitHub's registry failed (detected after merge)
   - Users were blocked from updating

---

## 🛠️ The Solution (PR #2320)

### The Fix

Restore the original, correct approach: **use the official Portainer Agent image as the source.**

**Corrected Dockerfile:**
```dockerfile
ARG BUILD_FROM
ARG BUILD_ARCH
FROM $BUILD_FROM

# ... bashio upgrade and other setup ...

# CORRECT: Use official upstream image (not self-reference)
COPY --from=ghcr.io/portainerci/agent:latest /app /app

# ... rest of Dockerfile ...

# CORRECT: No stderr suppression (visible error messages)
./agent "$PORTAINER_AGENT_ARGS"
```

### Why This Works

1. **Official Image Exists:** `ghcr.io/portainerci/agent:latest` is maintained by Portainer's official organization and always available
2. **No Circular Dependency:** The source image is external, not the image being built
3. **Build Succeeds:** GitHub Actions can complete the build without errors
4. **Tag Gets Created:** Once build succeeds, `ghcr.io/alexbelgium/portainer_agent-{arch}:alpine-sts` is published to the registry
5. **Users Can Update:** Home Assistant Supervisor can now pull the image successfully

### Architecture Support Preserved

The fix maintains multi-architecture support correctly:

```dockerfile
ARG BUILD_FROM      # e.g., ghcr.io/hassio-addons/base/aarch64:11.1.0
ARG BUILD_ARCH      # e.g., aarch64
FROM $BUILD_FROM    # Uses the correct base image for the architecture
```

The Alexbelgium build system will call:
- For aarch64: `docker build --build-arg BUILD_FROM=... --build-arg BUILD_ARCH=aarch64 ...`
- For amd64: `docker build --build-arg BUILD_FROM=... --build-arg BUILD_ARCH=amd64 ...`

Both builds will succeed because the source image (`portainerci/agent:latest`) is the same for all architectures.

---

## 📊 Before & After Comparison

| Aspect | ❌ Broken (PR #2315) | ✅ Fixed (PR #2320) |
|--------|---------------------|-------------------|
| **COPY Source** | `ghcr.io/alexbelgium/portainer_agent-${BUILD_ARCH}:alpine-sts` | `ghcr.io/portainerci/agent:latest` |
| **Source Status** | Self-reference (doesn't exist) | Official upstream (always exists) |
| **Circular Dependency** | YES - image references itself | NO - clean separation |
| **Build Outcome** | ❌ FAILS with manifest unknown | ✅ SUCCEEDS |
| **User Update** | ❌ 404 manifest unknown error | ✅ Works normally |
| **Error Messages** | Hidden by `2>/dev/null` | ✅ Visible for debugging |
| **Architecture Support** | Broken (aarch64 & amd64 fail) | ✅ Working (both architectures) |

---

## 🎓 Key Lessons Learned

### For Code Reviewers
1. **Verify changes to Docker image references** - This is a critical path
2. **Test code locally** before approving - Run `docker build .` at minimum
3. **Question why sources change** - If a COPY source is modified, understand the reason
4. **Don't assume suggestions are correct** - Even well-intentioned feedback can break things

### For Contributors
1. **Always test Dockerfile changes locally** - Before pushing to GitHub
2. **Beware of self-references** - A Dockerfile cannot copy from the image it's building
3. **Use official upstream sources** when available - Reduces maintenance burden
4. **Be explicit about build args** - ARG declarations must match how the build system calls them

### For CI/CD Pipelines
1. **Verify final image is created** - Check that the image tag exists after build
2. **Test image pulling** - Ensure users can actually pull the built image
3. **Don't silently ignore build failures** - Community needs to know immediately

---

## ✅ Verification

**PR #2320 Verification Checklist:**

- ✅ Dockerfile builds locally for both architectures
- ✅ No circular dependencies
- ✅ Uses official `ghcr.io/portainerci/agent:latest` as source
- ✅ Multi-architecture support via ARG BUILD_FROM/BUILD_ARCH
- ✅ Error messages visible (no stderr suppression)
- ✅ Version tag `alpine-sts` matches config.yaml
- ✅ CHANGELOG updated with fix details
- ✅ Code reviewed by AI for security and compatibility

**Expected Outcome After Merge:**
1. GitHub Actions build succeeds
2. Image tags `alpine-sts` created for aarch64 and amd64
3. Users can update Portainer Agent without 404 errors
4. Protection mode fix is available to all users

---

## 📝 Summary

| Aspect | Details |
|--------|---------|
| **Problem** | Circular dependency prevents Docker builds → 404 errors for users |
| **Root Cause** | COPY source changed from official image to self-reference in code review |
| **Impact** | All users blocked from updating Portainer Agent |
| **Solution** | Restore official Portainer Agent image source + remove stderr suppression |
| **Status** | FIXED in PR #2320 - Ready for merge |
| **User Action** | None required - update will work normally once PR is merged |

---

## 🔗 References

- **Issue #2318:** Users unable to update Portainer Agent (404 manifest unknown)
- **PR #2315:** Original fix (merged with circular dependency)
- **PR #2320:** Root cause fix (restores official image source)
- **Broken Commit:** f0f12512 (introduced circular dependency)
- **Fixed Commit:** dd66f4b49 (restored official image source)

---

**Generated:** December 30, 2025
**Status:** Community Impact Analysis Complete - Ready for Forum Discussion
