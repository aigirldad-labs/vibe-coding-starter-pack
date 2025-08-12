# install.ps1
# Run in an elevated PowerShell (Run as Administrator)

Write-Host "🚀 Vibe Coding Starter Pack setup starting..." -ForegroundColor Cyan

function Ensure-Choco {
  if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "📦 Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
  } else {
    Write-Host "✅ Chocolatey already installed."
  }
}

function Choco-Install($pkg) {
  Write-Host "📦 Installing $pkg..."
  choco install $pkg -y --no-progress --ignore-checksums
}

function Wait-For-Docker {
  Write-Host "🔎 Checking Docker engine..."
  $max = 60
  for ($i=1; $i -le $max; $i++) {
    try {
      docker info *> $null
      if ($LASTEXITCODE -eq 0) { 
        Write-Host "✅ Docker is available."
        return
      }
    } catch {}
    Start-Sleep -Seconds 3
  }
  throw "❌ Docker did not become available. Open Rancher Desktop, set Container Engine to 'dockerd (moby)', then re-run this script."
}

# 1) Ensure Chocolatey
Ensure-Choco

# 2) Install core tools
# Rancher Desktop provides the Docker engine. VS Code & Git for dev.
Choco-Install "git"
Choco-Install "visualstudiocode"
Choco-Install "rancher-desktop"

Write-Host "ℹ️ Ensure Rancher Desktop is set to 'dockerd (moby)'. If you just installed Rancher, start it now."
Write-Host "   - Open Rancher Desktop → Settings → Container Engine → select 'dockerd (moby)'."
Write-Host "   - Disable Kubernetes (optional)."
Write-Host "   - After switching, Rancher may prompt to restart the backend."

# 3) Wait for Docker to be available
Wait-For-Docker

# 4) Prepare workspace
$Root = Join-Path $HOME "vibe-coding"
if (-not (Test-Path $Root)) { New-Item -ItemType Directory -Path $Root | Out-Null }

# 5) Clone the n8n self-hosted AI starter kit
$KitDir = Join-Path $Root "self-hosted-ai-starter-kit"
if (-not (Test-Path $KitDir)) {
  Write-Host "⬇️ Cloning self-hosted AI starter kit..."
  git clone https://github.com/n8n-io/self-hosted-ai-starter-kit.git $KitDir
} else {
  Write-Host "🔁 Repository already exists. Pulling latest..."
  Push-Location $KitDir
  git pull
  Pop-Location
}

# 6) Start the stack (CPU profile)
Write-Host "🐳 Pulling images..."
docker compose pull

Write-Host "🚀 Starting containers (CPU profile)..."
docker compose --profile cpu up -d

Pop-Location

Write-Host "🎉 Setup complete!"
Write-Host "   n8n:        http://localhost:5678"
Write-Host "   Ollama API: http://localhost:11434 (exposed by the stack)"
