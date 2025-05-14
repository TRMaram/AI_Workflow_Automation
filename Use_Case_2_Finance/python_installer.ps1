# Set the path to the Downloads folder
$downloadsDir = [Environment]::GetFolderPath("Downloads")

# Check if Python is already installed
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Python not found. Downloading installer..."

    # Define the download URL and destination path
    $pythonUrl = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
    $pythonInstaller = Join-Path $downloadsDir "python-3.12.0-amd64.exe"

    try {
        # Download the installer
        Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller

        Write-Host "Launching the Python installer..."

        # Launch the installer with GUI
        Start-Process -FilePath $pythonInstaller -Wait

        Write-Host "Installer finished. If you installed Python, restart your terminal and run 'python --version' to verify."
    }
    catch {
        Write-Host "Failed to run Python installer: $($_.Exception.Message)"
        exit 1
    }
}
else {
    $pythonVersion = (& python --version)
    Write-Host "Python is already installed: $pythonVersion"
}
