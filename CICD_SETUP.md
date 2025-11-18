# CI/CD Pipeline Setup Guide

Quick guide to set up the GitHub Actions CI/CD pipeline for the ML Inference Service.

## Prerequisites

- GitHub repository for this project
- Docker Hub account (username: `vendettaopppp`)
- Git configured locally

---

## Step 1: Create Docker Hub Access Token (5 minutes)

1. **Go to Docker Hub**: https://hub.docker.com
2. **Login** with your credentials (username: `vendettaopppp`)
3. **Navigate to Account Settings**:
   - Click your profile icon (top right)
   - Select "Account Settings"
4. **Go to Security Tab**:
   - Click "Security" in the left sidebar
5. **Generate New Token**:
   - Click "New Access Token"
   - Description: `GitHub Actions CI/CD`
   - Access permissions: `Read, Write, Delete`
   - Click "Generate"
6. **Copy the Token**:
   - **IMPORTANT**: Copy the token immediately - you won't see it again!
   - Save it temporarily in a secure location

---

## Step 2: Add Secrets to GitHub Repository (3 minutes)

1. **Go to Your GitHub Repository**:
   - Navigate to: `https://github.com/YOUR_USERNAME/YOUR_REPO`

2. **Open Settings**:
   - Click "Settings" tab (top right)

3. **Navigate to Secrets**:
   - In left sidebar: "Secrets and variables" → "Actions"

4. **Add First Secret - DOCKERHUB_USERNAME**:
   - Click "New repository secret"
   - Name: `DOCKERHUB_USERNAME`
   - Value: `vendettaopppp`
   - Click "Add secret"

5. **Add Second Secret - DOCKERHUB_TOKEN**:
   - Click "New repository secret"
   - Name: `DOCKERHUB_TOKEN`
   - Value: (paste the token from Step 1)
   - Click "Add secret"

**Verify**: You should now see two secrets listed:
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

---

## Step 3: Push to Main Branch (2 minutes)

The pipeline triggers automatically on push to `main` branch.

```bash
# Make sure you're on main branch
git checkout main

# Add all files
git add .

# Commit
git commit -m "Add CI/CD pipeline with Trivy security scanning"

# Push to GitHub
git push origin main
```

---

## Step 4: Monitor Workflow (5-10 minutes)

1. **Go to Actions Tab**:
   - In your GitHub repository, click "Actions" tab

2. **Watch the Workflow**:
   - You'll see "CI/CD Pipeline" running
   - Click on the workflow run to see details

3. **Pipeline Stages**:
   ```
   ✅ Checkout code
   ✅ Set up Docker Buildx
   ✅ Generate image tags
   ✅ Build Docker image
   ✅ Run Trivy vulnerability scanner
   ✅ Run Trivy scan for GitHub Security
   ✅ Login to Docker Hub
   ✅ Push Docker image to Docker Hub
   ✅ Output image details
   ```

4. **Expected Duration**: 5-10 minutes (first run may be slower)

5. **If Pipeline Fails**:
   - Click on the failed step to see logs
   - Common issues:
     - **Secrets not set correctly**: Re-check Step 2
     - **Trivy found vulnerabilities**: Review security tab, update dependencies
     - **Docker Hub login failed**: Verify token hasn't expired

---

## Step 5: Verify Image in Docker Hub (2 minutes)

1. **Go to Docker Hub**: https://hub.docker.com/r/vendettaopppp/ml-inference-service

2. **Check for Tags**:
   - You should see two tags:
     - `latest` - Most recent build
     - `sha-XXXXXXX` - Specific commit SHA

3. **Pull the Image** (optional test):
   ```bash
   docker pull vendettaopppp/ml-inference-service:latest
   ```

4. **Run Locally** (optional test):
   ```bash
   docker run -d -p 8000:8000 \
     -e TENANT_NAME=test \
     vendettaopppp/ml-inference-service:latest
   
   # Test it
   curl http://localhost:8000/health
   ```

---

## ✅ Success Checklist

- [ ] Docker Hub access token created
- [ ] GitHub secrets added (DOCKERHUB_USERNAME, DOCKERHUB_TOKEN)
- [ ] Code pushed to main branch
- [ ] GitHub Actions workflow completed successfully
- [ ] Docker image visible on Docker Hub
- [ ] Image has both `latest` and SHA tags

---

## 🔄 Using the Pipeline

### Automatic Triggers

The pipeline runs automatically when you:
- Push to `main` branch
- Merge a pull request to `main`

### Manual Trigger

You can also trigger manually:
1. Go to "Actions" tab
2. Click "CI/CD Pipeline"
3. Click "Run workflow"
4. Select branch (usually `main`)
5. Click "Run workflow"

---

## 📊 Understanding the Pipeline

### Build Stage
- Builds Docker image from `ml-inference-service/Dockerfile`
- Uses Docker Buildx for efficient builds
- Caches layers for faster subsequent builds

### Security Scan Stage
- Runs Trivy to scan for vulnerabilities
- Checks OS packages and application libraries
- Fails pipeline if HIGH or CRITICAL vulnerabilities found
- Uploads results to GitHub Security tab

### Push Stage
- Logs into Docker Hub using secrets
- Pushes two tags:
  - `latest` - always points to newest build
  - `sha-XXXXXXX` - specific commit for rollback

---

## 🐛 Troubleshooting

### "Secrets not found" Error
```
Error: secrets.DOCKERHUB_USERNAME is not set
```
**Fix**: Go back to Step 2 and add the secrets

### "Authentication failed" Error
```
Error: unauthorized: incorrect username or password
```
**Fix**: 
- Verify Docker Hub username is correct
- Generate a new access token
- Update `DOCKERHUB_TOKEN` secret

### "Trivy scan failed" Error
```
Error: vulnerabilities found (exit code 1)
```
**Fix**:
- Review the vulnerability report in the logs
- Update base image in Dockerfile
- Update dependencies in requirements.txt
- Or temporarily disable the check (not recommended)

### "Docker push failed" Error
```
Error: denied: requested access to the resource is denied
```
**Fix**:
- Verify repository exists on Docker Hub
- Check token has write permissions
- Repository might need to be created first (it auto-creates, but check)

---

## 🔒 Security Best Practices

1. **Never commit secrets** to git
2. **Rotate tokens** every 90 days
3. **Use read-only tokens** for pulling images
4. **Review Trivy results** in Security tab
5. **Keep dependencies updated** regularly

---

## 📚 Next Steps

- See `CI_CD_DOCUMENTATION.md` for detailed pipeline explanation
- See `EKS_DEPLOYMENT_GUIDE.md` for EKS deployment (when ready)
- Monitor GitHub Security tab for vulnerabilities
- Set up branch protection rules for `main`

---

## 🎉 You're Done!

Your CI/CD pipeline is now set up! Every push to `main` will:
1. Build the Docker image
2. Scan for security vulnerabilities
3. Push to Docker Hub automatically

Happy deploying! 🚀

