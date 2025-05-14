# Define temp dir for download
$tempDir = $env:TEMP

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Python not found. Downloading installer..." -ForegroundColor Magenta

    # Download Python installer
    $pythonUrl = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
    $pythonInstaller = Join-Path $tempDir "python_installer.exe"

    try {
        Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller

        Write-Host "Launching interactive installer..." -ForegroundColor Cyan

        # Run installer with UI so the user can choose options
        Start-Process -FilePath $pythonInstaller -Wait

        Write-Host "✅ Installer closed. If you installed Python, restart your terminal and test with: python --version" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to run Python installer: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
else {
    $pythonVersion = (& python --version)
    Write-Host "✅ Python is already installed: $pythonVersion" -ForegroundColor Green
}
