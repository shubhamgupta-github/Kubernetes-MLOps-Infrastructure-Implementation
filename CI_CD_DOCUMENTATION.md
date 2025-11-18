# CI/CD Pipeline Documentation

Complete documentation for the GitHub Actions CI/CD pipeline.

## Overview

This pipeline automates the build, security scanning, and deployment of the ML Inference Service Docker image to Docker Hub.

**Pipeline File**: `.github/workflows/ci-cd.yml`

---

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Actions Workflow                   │
│                                                               │
│  Trigger: Push to main branch                                │
│           Manual workflow_dispatch                           │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Stage 1: Setup & Checkout                          │   │
│  │  • Checkout code from repository                    │   │
│  │  • Set up Docker Buildx                             │   │
│  │  • Generate image tags (SHA + latest)               │   │
│  └─────────────────────────────────────────────────────┘   │
│                          ↓                                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Stage 2: Build Docker Image                        │   │
│  │  • Build from ml-inference-service/Dockerfile       │   │
│  │  • Tag with SHA and latest                          │   │
│  │  • Use layer caching for speed                      │   │
│  │  • Load image for scanning                          │   │
│  └─────────────────────────────────────────────────────┘   │
│                          ↓                                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Stage 3: Security Scan (Trivy)                     │   │
│  │  • Scan for OS vulnerabilities                      │   │
│  │  • Scan for library vulnerabilities                 │   │
│  │  • Fail on CRITICAL/HIGH severity                   │   │
│  │  • Upload results to GitHub Security                │   │
│  └─────────────────────────────────────────────────────┘   │
│                          ↓                                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Stage 4: Push to Docker Hub                        │   │
│  │  • Login using secrets                              │   │
│  │  • Push vendettaopppp/ml-inference-service:SHA      │   │
│  │  • Push vendettaopppp/ml-inference-service:latest   │   │
│  │  • Output image details to summary                  │   │
│  └─────────────────────────────────────────────────────┘   │
│                          ↓                                    │
│  ✅ Pipeline Complete                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## Pipeline Stages Explained

### Stage 1: Setup & Checkout

**Purpose**: Prepare the build environment

**Steps**:
1. **Checkout code** (`actions/checkout@v4`)
   - Clones the repository
   - Includes full git history for SHA generation

2. **Set up Docker Buildx** (`docker/setup-buildx-action@v3`)
   - Enables advanced Docker features
   - Required for layer caching
   - Provides build performance improvements

3. **Generate image tags**
   - Extracts short commit SHA (first 7 characters)
   - Generates timestamp
   - Sets outputs for later steps

**Output**: 
- `sha_short`: e.g., `abc1234`
- `date`: e.g., `20240115-143022`

---

### Stage 2: Build Docker Image

**Purpose**: Build the ML inference service container

**Configuration**:
```yaml
context: ml-inference-service/
file: ml-inference-service/Dockerfile
tags:
  - vendettaopppp/ml-inference-service:abc1234
  - vendettaopppp/ml-inference-service:latest
```

**Features**:
- **Multi-tagging**: Creates both SHA and latest tags simultaneously
- **Layer caching**: Uses GitHub Actions cache for faster builds
- **Load locally**: Keeps image in local Docker for scanning

**Build Time**: 3-5 minutes (first run), 1-2 minutes (cached)

**What Gets Built**:
- Base: Python 3.11-slim
- Dependencies: FastAPI, scikit-learn, numpy, etc.
- Application: ML inference service
- User: Non-root (UID 1000)

---

### Stage 3: Security Scan (Trivy)

**Purpose**: Identify security vulnerabilities before deployment

#### Scan 1: Console Output (Fails Pipeline)

**Configuration**:
```yaml
format: table
exit-code: 1
severity: CRITICAL,HIGH
vuln-type: os,library
```

**Behavior**:
- Scans the built Docker image
- Checks OS packages (Debian/Python base)
- Checks Python libraries (requirements.txt)
- **Fails pipeline** if HIGH or CRITICAL vulnerabilities found
- Ignores unfixed vulnerabilities (optional)

**Output Example**:
```
+------------------+------------------+----------+-------------------+
| Library          | Vulnerability    | Severity | Installed Version |
+------------------+------------------+----------+-------------------+
| python3.11       | CVE-2024-12345   | HIGH     | 3.11.0            |
| numpy            | CVE-2024-67890   | CRITICAL | 1.24.3            |
+------------------+------------------+----------+-------------------+
```

#### Scan 2: GitHub Security Tab (Information Only)

**Configuration**:
```yaml
format: sarif
output: trivy-results.sarif
```

**Behavior**:
- Generates SARIF report (industry standard)
- Uploads to GitHub Security tab
- Provides detailed vulnerability tracking
- Doesn't fail the pipeline
- Integrates with Dependabot

**View Results**: Repository → Security tab → Code scanning alerts

---

### Stage 4: Push to Docker Hub

**Purpose**: Publish the image to Docker Hub registry

**Authentication**:
```yaml
username: ${{ secrets.DOCKERHUB_USERNAME }}
password: ${{ secrets.DOCKERHUB_TOKEN }}
```

**Push Operations**:
1. Login to Docker Hub
2. Push `vendettaopppp/ml-inference-service:SHA`
3. Push `vendettaopppp/ml-inference-service:latest`

**Result**: Two tags available on Docker Hub
- `latest` - Always points to newest build from main
- `sha-abc1234` - Specific commit, immutable, for rollback

**Summary Output**:
The pipeline creates a nice summary in GitHub Actions with:
- Image tags pushed
- Pull command
- Link to Docker Hub

---

## Environment Variables

```yaml
DOCKER_IMAGE: vendettaopppp/ml-inference-service
DOCKERFILE_PATH: ml-inference-service/Dockerfile
BUILD_CONTEXT: ml-inference-service
```

**Purpose**: Centralized configuration, easy to change

---

## GitHub Secrets Required

### 1. DOCKERHUB_USERNAME

**Value**: `vendettaopppp`
**Purpose**: Docker Hub account username
**How to Add**:
1. Repository Settings → Secrets and variables → Actions
2. New repository secret
3. Name: `DOCKERHUB_USERNAME`
4. Value: `vendettaopppp`

### 2. DOCKERHUB_TOKEN

**Value**: Your Docker Hub Personal Access Token
**Purpose**: Authentication for pushing images

**How to Create**:
1. Go to https://hub.docker.com
2. Account Settings → Security
3. New Access Token
4. Description: "GitHub Actions CI/CD"
5. Permissions: Read, Write, Delete
6. Copy the token (you won't see it again!)

**How to Add**:
1. Repository Settings → Secrets and variables → Actions
2. New repository secret
3. Name: `DOCKERHUB_TOKEN`
4. Value: (paste the token)

**Security Notes**:
- Never commit tokens to git
- Tokens are encrypted by GitHub
- Only visible to workflow runs
- Rotate every 90 days

---

## Triggers

### Automatic Triggers

**Push to Main Branch**:
```yaml
on:
  push:
    branches:
      - main
```

When triggered:
- Direct push to main
- Merged pull request to main
- Fast-forward merge

**What doesn't trigger**:
- Push to feature branches
- Pull request creation (without merge)
- Tag creation

### Manual Trigger

```yaml
on:
  workflow_dispatch:
```

**How to Use**:
1. Go to Actions tab
2. Select "CI/CD Pipeline"
3. Click "Run workflow"
4. Choose branch
5. Click "Run workflow"

**Use Cases**:
- Rebuild image without code changes
- Test pipeline modifications
- Emergency hotfix deployment

---

## Image Tagging Strategy

### Why Two Tags?

**1. Latest Tag** (`latest`)
- Always points to most recent build from main
- Easy to reference
- Simple pull command: `docker pull vendettaopppp/ml-inference-service:latest`
- Good for: Development, testing, "always use newest"

**2. SHA Tag** (`sha-abc1234`)
- Immutable - never changes
- Traceable to exact commit
- Enables rollback to specific version
- Good for: Production, audit trail, troubleshooting

### Tag Format

```
vendettaopppp/ml-inference-service:sha-<7-char-commit-sha>
vendettaopppp/ml-inference-service:latest
```

**Example**:
- Commit SHA: `abc1234567890`
- Short SHA: `abc1234`
- Tag: `sha-abc1234`

### Using Tags in Kubernetes

**Latest (auto-update)**:
```yaml
image: vendettaopppp/ml-inference-service:latest
imagePullPolicy: Always
```

**Specific version (stable)**:
```yaml
image: vendettaopppp/ml-inference-service:sha-abc1234
imagePullPolicy: IfNotPresent
```

---

## Trivy Security Scan Details

### What Trivy Checks

1. **OS Vulnerabilities**:
   - Debian package vulnerabilities
   - Python interpreter vulnerabilities
   - System libraries

2. **Application Dependencies**:
   - Python packages (from requirements.txt)
   - Known CVEs in libraries
   - Outdated dependencies

### Severity Levels

| Level | Description | Action |
|-------|-------------|--------|
| CRITICAL | Actively exploited, severe impact | ❌ Fail pipeline |
| HIGH | Serious vulnerability | ❌ Fail pipeline |
| MEDIUM | Moderate risk | ⚠️ Warning only |
| LOW | Minor issue | ℹ️ Info only |

### Current Configuration

```yaml
severity: 'CRITICAL,HIGH'
exit-code: '1'
```

**Meaning**: Pipeline fails if CRITICAL or HIGH severity issues found

### How to Handle Failures

**Option 1: Fix the Vulnerability** (Recommended)
```bash
# Update dependency in requirements.txt
# Rebuild and push
```

**Option 2: Update Base Image**
```dockerfile
# Change FROM line in Dockerfile
FROM python:3.11-slim  # to newer version
```

**Option 3: Temporarily Ignore** (Not recommended)
```yaml
# In ci-cd.yml, change:
exit-code: '0'  # Don't fail on vulnerabilities
```

### Viewing Scan Results

**In Workflow Logs**:
- Click on workflow run
- Click "Run Trivy vulnerability scanner" step
- See table output

**In Security Tab**:
- Repository → Security → Code scanning
- See all detected issues
- Track remediation

---

## Performance Optimization

### Layer Caching

```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```

**Benefit**: 
- First build: 5-7 minutes
- Cached build: 1-2 minutes
- Saves GitHub Actions minutes

**How it Works**:
- Caches Docker layers in GitHub Actions cache
- Reuses layers if Dockerfile/dependencies unchanged
- Invalidates on changes

### Build Time Breakdown

| Step | First Run | Cached Run |
|------|-----------|------------|
| Checkout | 5s | 5s |
| Setup Buildx | 10s | 10s |
| Build Image | 4-5 min | 30s-1min |
| Trivy Scan | 1-2 min | 1-2 min |
| Push to Docker Hub | 1-2 min | 1-2 min |
| **Total** | **7-10 min** | **3-5 min** |

---

## Monitoring & Alerts

### Success Indicators

✅ All steps show green checkmarks
✅ Summary shows image tags
✅ Image visible on Docker Hub
✅ Security tab shows scan results

### Failure Notifications

GitHub can notify you on failure:
1. Repository Settings → Notifications
2. Configure email/Slack/webhooks
3. Get alerted on pipeline failures

### Viewing History

- Actions tab → CI/CD Pipeline
- See all runs
- Filter by status, branch, date
- View logs for debugging

---

## Best Practices

### 1. Don't Skip Security Scans
- Always run Trivy before pushing
- Fix CRITICAL/HIGH issues immediately
- Review MEDIUM issues regularly

### 2. Use Specific Tags in Production
```yaml
# Good
image: vendettaopppp/ml-inference-service:sha-abc1234

# Bad for production
image: vendettaopppp/ml-inference-service:latest
```

### 3. Rotate Secrets Regularly
- Docker Hub tokens every 90 days
- Update GitHub secrets when rotated
- Use calendar reminders

### 4. Monitor Image Size
- Check Docker Hub for image size
- Optimize Dockerfile if too large
- Clean up old images periodically

### 5. Branch Protection
- Enable branch protection for main
- Require PR reviews
- Require status checks to pass

---

## Troubleshooting

### Common Issues

**Issue**: Secrets not found
```
Error: secrets.DOCKERHUB_USERNAME is not set
```
**Fix**: Add secrets to repository settings

**Issue**: Authentication failed
```
Error: unauthorized: incorrect username or password
```
**Fix**: Regenerate Docker Hub token, update secret

**Issue**: Trivy scan failed
```
Error: detected 5 vulnerabilities (exit code 1)
```
**Fix**: Update dependencies or base image

**Issue**: Build timeout
```
Error: The job running on runner has exceeded the maximum execution time
```
**Fix**: Optimize Dockerfile, reduce image size

**Issue**: Push failed - repository not found
```
Error: repository does not exist
```
**Fix**: Create repository on Docker Hub first (or wait, it auto-creates)

---

## Future Enhancements

Potential improvements to consider:

1. **Multi-architecture builds**: ARM64 + AMD64
2. **Automated testing**: Run tests before build
3. **Image signing**: Cosign for supply chain security
4. **SBOM generation**: Software Bill of Materials
5. **Staging deployment**: Auto-deploy to staging environment
6. **Slack notifications**: Notify team on failures
7. **Rollback automation**: Auto-rollback on deployment failure

---

## Related Documentation

- `CICD_SETUP.md` - Quick setup guide
- `EKS_DEPLOYMENT_GUIDE.md` - EKS deployment (theoretical)
- `.github/workflows/ci-cd.yml` - Pipeline source code
- `ml-inference-service/Dockerfile` - Container definition

---

## Summary

This CI/CD pipeline provides:
- ✅ Automated builds on every main branch push
- ✅ Security vulnerability scanning
- ✅ Automatic Docker Hub publishing
- ✅ Version tracking with SHA tags
- ✅ GitHub Security integration
- ✅ Fast builds with caching

**Result**: Safe, automated, and traceable deployments! 🚀

