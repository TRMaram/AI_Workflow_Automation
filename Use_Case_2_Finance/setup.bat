# PowerShell Script Corrigé pour Streamlit & n8n Setup sur Windows
# Ce script installe et configure Streamlit et n8n sur des systèmes Windows 10+
# Exécutez ce script avec des privilèges administrateur pour de meilleurs résultats

# Afficher l'en-tête
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "🚀 Script d'installation automatisé Streamlit & n8n pour Windows" -ForegroundColor Cyan
Write-Host "🔧 Exécution en mode répertoire courant" -ForegroundColor Cyan
Write-Host "🔶 Utilisation de l'installation locale n8n (npm) au lieu de Docker" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Fonction pour vérifier si une commande existe
function Test-CommandExists {
    param (
        [string]$Command
    )
    
    try {
        if (Get-Command $Command -ErrorAction Stop) {
            return $true
        }
    }
    catch {
        return $false
    }
    return $false
}

# Fonction pour vérifier si un port est utilisé
function Test-PortInUse {
    param (
        [int]$Port
    )
    
    $connections = Get-NetTCPConnection -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -eq $Port }
    return $null -ne $connections
}

# Fonction pour inviter l'utilisateur et installer si nécessaire
function Check-AndInstall {
    param (
        [string]$Tool,
        [string]$InstallCmd,
        [string]$CheckCmd = $Tool
    )
    
    Write-Host "📋 Vérification si $Tool est installé..." -ForegroundColor Yellow
    if (Test-CommandExists $CheckCmd) {
        Write-Host "✅ $Tool est déjà installé." -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "❌ $Tool n'est pas installé." -ForegroundColor Red
        $installChoice = Read-Host "📥 Voulez-vous installer $Tool maintenant ? (o/n)"
        if ($installChoice -eq "o" -or $installChoice -eq "O" -or $installChoice -eq "y" -or $installChoice -eq "Y") {
            Write-Host "📦 Installation de $Tool..." -ForegroundColor Yellow
            try {
                Invoke-Expression $InstallCmd
                
                # Vérifier si l'installation a réussi
                if (Test-CommandExists $CheckCmd) {
                    Write-Host "✅ $Tool a été installé avec succès." -ForegroundColor Green
                    return $true
                }
                else {
                    Write-Host "❌ L'installation de $Tool a échoué. Veuillez l'installer manuellement et réexécuter ce script." -ForegroundColor Red
                    return $false
                }
            }
            catch {
                Write-Host "❌ Erreur lors de l'installation de $Tool: $_" -ForegroundColor Red
                return $false
            }
        }
        else {
            Write-Host "⚠️ $Tool est nécessaire pour continuer. Sortie du script." -ForegroundColor Red
            return $false
        }
    }
}

# Vérifier si le script s'exécute en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "⚠️ Ce script ne s'exécute pas avec des privilèges d'administrateur." -ForegroundColor Yellow
    Write-Host "⚠️ Certaines opérations peuvent échouer. Envisagez de redémarrer en tant qu'administrateur." -ForegroundColor Yellow
    $continueAnyway = Read-Host "🔄 Continuer quand même ? (o/n)"
    if ($continueAnyway -ne "o" -and $continueAnyway -ne "O" -and $continueAnyway -ne "y" -and $continueAnyway -ne "Y") {
        exit
    }
}

# Vérifier l'installation de Python
Write-Host "📋 Vérification de l'installation Python..." -ForegroundColor Yellow
$pythonCommand = $null

# Essayer les commandes Python possibles
foreach ($cmd in @("python", "python3", "py")) {
    if (Test-CommandExists $cmd) {
        $pythonCommand = $cmd
        break
    }
}

if ($pythonCommand) {
    Write-Host "✅ Python trouvé: $pythonCommand" -ForegroundColor Green
    
    # Vérifier la version de Python
    try {
        $pythonVersionOutput = & $pythonCommand --version 2>&1
        if ($pythonVersionOutput -is [string]) {
            $pythonVersion = $pythonVersionOutput.Split(" ")[1]
        }
        else {
            $pythonVersion = $pythonVersionOutput.ToString().Split(" ")[1]
        }
        
        Write-Host "✅ Python $pythonVersion trouvé" -ForegroundColor Green
        
        # Vérifier si la version de Python est compatible (3.9-3.11 recommandée pour Streamlit)
        $pythonMajor = [int]($pythonVersion.Split(".")[0])
        $pythonMinor = [int]($pythonVersion.Split(".")[1])
        
        if ($pythonMajor -eq 3 -and $pythonMinor -ge 9 -and $pythonMinor -le 11) {
            Write-Host "✅ Python $pythonVersion est compatible avec Streamlit." -ForegroundColor Green
        }
        else {
            Write-Host "⚠️ Python $pythonVersion peut ne pas être entièrement compatible avec Streamlit." -ForegroundColor Yellow
            Write-Host "ℹ️ La version recommandée est Python 3.9-3.11." -ForegroundColor Yellow
            $continueChoice = Read-Host "🔄 Continuer quand même ? (o/n)"
            if ($continueChoice -ne "o" -and $continueChoice -ne "O" -and $continueChoice -ne "y" -and $continueChoice -ne "Y") {
                exit
            }
        }
    }
    catch {
        Write-Host "⚠️ Impossible de déterminer la version de Python. Continuons quand même." -ForegroundColor Yellow
    }
}
else {
    Write-Host "❌ Python non trouvé." -ForegroundColor Red
    $installChoice = Read-Host "📥 Voulez-vous installer Python maintenant ? (o/n)"
    if ($installChoice -eq "o" -or $installChoice -eq "O" -or $installChoice -eq "y" -or $installChoice -eq "Y") {
        Write-Host "📥 Ouverture de la page de téléchargement Python..." -ForegroundColor Yellow
        Start-Process "https://www.python.org/downloads/"
        Write-Host "ℹ️ Veuillez installer Python 3.9-3.11 et assurez-vous de cocher 'Add Python to PATH'" -ForegroundColor Yellow
        Write-Host "ℹ️ Après l'installation, veuillez redémarrer ce script." -ForegroundColor Yellow
        exit
    }
    else {
        Write-Host "❌ Python est nécessaire pour continuer. Sortie du script." -ForegroundColor Red
        exit
    }
}

# Vérifier l'installation de pip
$pipCommand = $null
if (Test-CommandExists "pip") {
    $pipCommand = "pip"
}
elseif (Test-CommandExists "pip3") {
    $pipCommand = "pip3"
}

if ($pipCommand) {
    Write-Host "✅ $pipCommand est installé." -ForegroundColor Green
}
else {
    Write-Host "❌ pip n'est pas installé." -ForegroundColor Red
    Write-Host "📥 Tentative d'installation de pip..." -ForegroundColor Yellow
    
    # Essayer d'installer pip
    try {
        & $pythonCommand -m ensurepip --upgrade
        
        # Vérifier si pip a été installé
        if (Test-CommandExists "pip") {
            $pipCommand = "pip"
            Write-Host "✅ pip installé avec succès." -ForegroundColor Green
        }
        elseif (Test-CommandExists "pip3") {
            $pipCommand = "pip3"
            Write-Host "✅ pip installé avec succès." -ForegroundColor Green
        }
        else {
            Write-Host "❌ Échec de l'installation de pip." -ForegroundColor Red
            Write-Host "📥 Téléchargement de get-pip.py..." -ForegroundColor Yellow
            
            try {
                Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile "get-pip.py"
                & $pythonCommand get-pip.py
                
                # Vérifier si pip a été installé
                if (Test-CommandExists "pip") {
                    $pipCommand = "pip"
                    Write-Host "✅ pip installé avec succès." -ForegroundColor Green
                }
                elseif (Test-CommandExists "pip3") {
                    $pipCommand = "pip3"
                    Write-Host "✅ pip installé avec succès." -ForegroundColor Green
                }
                else {
                    Write-Host "❌ Échec de l'installation de pip. Veuillez l'installer manuellement." -ForegroundColor Red
                    exit
                }
            }
            catch {
                Write-Host "❌ Erreur lors du téléchargement de get-pip.py: $_" -ForegroundColor Red
                exit
            }
        }
    }
    catch {
        Write-Host "❌ Erreur lors de l'installation de pip: $_" -ForegroundColor Red
        exit
    }
}

# Utiliser le répertoire courant comme dossier du projet
Write-Host "📂 Utilisation du répertoire courant comme dossier de projet" -ForegroundColor Yellow

$streamlitScript = Read-Host "📄 Entrez le nom de votre fichier script Streamlit (ex: app.py)"
if ([string]::IsNullOrEmpty($streamlitScript)) {
    $streamlitScript = "app.py"
    Write-Host "ℹ️ Utilisation du nom par défaut: $streamlitScript" -ForegroundColor Yellow
}

$workflowJson = Read-Host "📄 Entrez le chemin vers votre fichier de workflow n8n JSON (ou laissez vide si aucun)"
if (-not [string]::IsNullOrEmpty($workflowJson) -and -not (Test-Path $workflowJson)) {
    Write-Host "⚠️ Fichier de workflow n8n non trouvé à: $workflowJson" -ForegroundColor Yellow
    $continueChoice = Read-Host "🔄 Continuer sans fichier de workflow ? (o/n)"
    if ($continueChoice -ne "o" -and $continueChoice -ne "O" -and $continueChoice -ne "y" -and $continueChoice -ne "Y") {
        exit
    }
    $workflowJson = ""
}

# Déjà dans le dossier du projet
Write-Host "📍 Répertoire de travail: $(Get-Location)" -ForegroundColor Yellow

# Vérifier et créer l'environnement virtuel
Write-Host "🔧 Configuration de l'environnement virtuel Python..." -ForegroundColor Yellow

try {
    & $pythonCommand -m venv --help | Out-Null
    $venvAvailable = $true
}
catch {
    $venvAvailable = $false
}

if (-not $venvAvailable) {
    Write-Host "❌ Module Python venv non disponible." -ForegroundColor Red
    Write-Host "📥 Tentative d'installation de virtualenv..." -ForegroundColor Yellow
    try {
        & $pipCommand install virtualenv
        
        if (-not (Test-CommandExists "virtualenv")) {
            Write-Host "❌ Échec de l'installation de virtualenv. Veuillez l'installer manuellement." -ForegroundColor Red
            Write-Host "ℹ️ Exécutez: pip install virtualenv" -ForegroundColor Yellow
            exit
        }
    }
    catch {
        Write-Host "❌ Erreur lors de l'installation de virtualenv: $_" -ForegroundColor Red
        exit
    }
}

# Créer un environnement virtuel
Write-Host "🔧 Création de l'environnement virtuel Python..." -ForegroundColor Yellow
if (Test-Path "venv") {
    Write-Host "⚠️ Un environnement virtuel existe déjà." -ForegroundColor Yellow
    $recreateVenv = Read-Host "🔄 Recréer l'environnement virtuel ? (o/n)"
    if ($recreateVenv -eq "o" -or $recreateVenv -eq "O" -or $recreateVenv -eq "y" -or $recreateVenv -eq "Y") {
        Remove-Item -Recurse -Force "venv"
        try {
            if ($venvAvailable) {
                & $pythonCommand -m venv venv
            }
            else {
                & virtualenv venv
            }
            Write-Host "✅ Environnement virtuel recréé." -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Erreur lors de la création de l'environnement virtuel: $_" -ForegroundColor Red
            exit
        }
    }
    else {
        Write-Host "✅ Utilisation de l'environnement virtuel existant." -ForegroundColor Green
    }
}
else {
    try {
        if ($venvAvailable) {
            & $pythonCommand -m venv venv
        }
        else {
            & virtualenv venv
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Échec de la création de l'environnement virtuel." -ForegroundColor Red
            exit
        }
        Write-Host "✅ Environnement virtuel créé." -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Erreur lors de la création de l'environnement virtuel: $_" -ForegroundColor Red
        exit
    }
}

# Activer l'environnement virtuel
Write-Host "🔌 Activation de l'environnement virtuel..." -ForegroundColor Yellow
$activateScript = ".\venv\Scripts\Activate.ps1"
if (Test-Path $activateScript) {
    try {
        . $activateScript
        Write-Host "✅ Environnement virtuel activé." -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Erreur lors de l'activation de l'environnement virtuel: $_" -ForegroundColor Red
        Write-Host "ℹ️ Essayez d'exécuter manuellement: .\venv\Scripts\Activate.ps1" -ForegroundColor Yellow
        exit
    }
}
else {
    Write-Host "❌ Script d'activation non trouvé." -ForegroundColor Red
    Write-Host "ℹ️ Vérifiez que l'environnement virtuel a été correctement créé." -ForegroundColor Yellow
    exit
}

# Créer requirements.txt s'il n'existe pas
if (-not (Test-Path "requirements.txt")) {
    Write-Host "📝 Création de requirements.txt..." -ForegroundColor Yellow
    @"
streamlit>=1.24.0
requests>=2.28.0
pandas>=1.5.0
"@ | Out-File -FilePath "requirements.txt" -Encoding utf8
    Write-Host "✅ Fichier requirements.txt créé avec les dépendances de base" -ForegroundColor Green
}
else {
    Write-Host "✅ Utilisation du fichier requirements.txt existant" -ForegroundColor Green
    
    # Vérifier si streamlit est dans requirements.txt
    try {
        $requirementsContent = Get-Content "requirements.txt"
        if (-not ($requirementsContent -match "streamlit")) {
            Write-Host "⚠️ Streamlit non trouvé dans requirements.txt" -ForegroundColor Yellow
            $addStreamlit = Read-Host "📥 Ajouter streamlit à requirements.txt ? (o/n)"
            if ($addStreamlit -eq "o" -or $addStreamlit -eq "O" -or $addStreamlit -eq "y" -or $addStreamlit -eq "Y") {
                "streamlit>=1.24.0" | Out-File -FilePath "requirements.txt" -Append -Encoding utf8
                Write-Host "✅ Streamlit ajouté à requirements.txt" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Host "⚠️ Erreur lors de la lecture de requirements.txt: $_" -ForegroundColor Yellow
    }
}

# Installer les dépendances
Write-Host "📦 Installation des dépendances Python..." -ForegroundColor Yellow
try {
    & $pipCommand install -r requirements.txt
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Échec de l'installation des dépendances." -ForegroundColor Red
        $continueChoice = Read-Host "🔄 Continuer quand même ? (o/n)"
        if ($continueChoice -ne "o" -and $continueChoice -ne "O" -and $continueChoice -ne "y" -and $continueChoice -ne "Y") {
            exit
        }
    }
    else {
        Write-Host "✅ Dépendances installées avec succès." -ForegroundColor Green
        
        # Vérifier l'installation de streamlit
        $checkStreamlit = & $pythonCommand -c "import streamlit; print('ok')" 2>$null
        if ($checkStreamlit -eq "ok") {
            Write-Host "✅ Streamlit est disponible." -ForegroundColor Green
        }
        else {
            Write-Host "❌ Installation de Streamlit non trouvée." -ForegroundColor Red
            Write-Host "⚠️ Vous devrez peut-être l'installer manuellement ou redémarrer votre terminal." -ForegroundColor Yellow
            $installStreamlit = Read-Host "📥 Installer streamlit directement ? (o/n)"
            if ($installStreamlit -eq "o" -or $installStreamlit -eq "O" -or $installStreamlit -eq "y" -or $installStreamlit -eq "Y") {
                & $pipCommand install streamlit
                $checkStreamlit = & $pythonCommand -c "import streamlit; print('ok')" 2>$null
                if ($checkStreamlit -eq "ok") {
                    Write-Host "✅ Streamlit installé avec succès." -ForegroundColor Green
                }
                else {
                    Write-Host "❌ L'installation de Streamlit a échoué." -ForegroundColor Red
                    exit
                }
            }
        }
    }
}
catch {
    Write-Host "❌ Erreur lors de l'installation des dépendances: $_" -ForegroundColor Red
    exit
}

# Créer l'intégration webhook Streamlit si elle n'existe pas
if (-not (Test-Path $streamlitScript)) {
    Write-Host "📝 Création du script d'intégration webhook Streamlit..." -ForegroundColor Yellow
    @"
import streamlit as st
import requests
import json
import os

# Configuration de la page
st.set_page_config(page_title="n8n Workflow Trigger", page_icon="🔄")

st.title("n8n Workflow Trigger")
st.write("Cliquez sur le bouton ci-dessous pour déclencher votre workflow n8n via webhook")

# Obtenir l'URL du webhook à partir de la variable d'environnement ou utiliser la valeur par défaut
N8N_WEBHOOK_URL = os.environ.get("N8N_WEBHOOK_URL", "http://localhost:5678/webhook/your-webhook-path")

# Permettre à l'utilisateur de définir l'URL du webhook dans l'interface
with st.sidebar:
    st.header("Configuration")
    webhook_url = st.text_input("URL du webhook n8n", value=N8N_WEBHOOK_URL)
    
    if st.button("Enregistrer l'URL du webhook", key="save_url"):
        N8N_WEBHOOK_URL = webhook_url
        st.success("URL du webhook mise à jour !")

# Fonction pour déclencher le webhook
def trigger_n8n_webhook():
    try:
        # Obtenir toute entrée utilisateur
        with st.expander("Paramètres du Webhook (Optionnel)", expanded=False):
            param_input = st.text_area("Paramètres JSON:", 
                                     value='{\n  "exemple": "valeur"\n}',
                                     height=150,
                                     help="Ajoutez des paramètres à envoyer à n8n au format JSON")
            
            # Analyser les paramètres JSON
            try:
                params = json.loads(param_input)
            except json.JSONDecodeError:
                st.warning("JSON invalide. Utilisation d'un ensemble de paramètres vide.")
                params = {}
        
        # Afficher un spinner pendant la requête
        with st.spinner("Déclenchement du workflow n8n..."):
            response = requests.post(webhook_url, json=params)
        
        # Vérifier si la requête a réussi
        if response.status_code in [200, 201]:
            st.success(f"Workflow déclenché avec succès ! Code de statut : {response.status_code}")
            
            # Afficher la réponse de n8n s'il y en a une
            if response.text:
                with st.expander("Détails de la réponse"):
                    try:
                        st.json(response.json())
                    except:
                        st.text(response.text)
        else:
            st.error(f"Échec du déclenchement du workflow. Code de statut : {response.status_code}")
            st.error(f"Réponse : {response.text}")
    
    except requests.exceptions.RequestException as e:
        st.error(f"Erreur de connexion à n8n : {str(e)}")
        st.info("Assurez-vous que n8n est en cours d'exécution et accessible.")
    except Exception as e:
        st.error(f"Une erreur inattendue s'est produite : {str(e)}")

# Créer un bouton visible pour déclencher le webhook
if st.button("🚀 Déclencher le workflow n8n", type="primary", use_container_width=True):
    trigger_n8n_webhook()

# Ajouter des informations utiles
with st.expander("Comment configurer votre webhook n8n"):
    st.markdown("""
    1. Dans n8n, ajoutez un **nœud Webhook** comme déclencheur pour votre workflow
    2. Configurez-le comme un webhook (plutôt qu'un webhook de test)
    3. Copiez l'URL du webhook depuis n8n
    4. Collez-la dans le champ **URL du webhook n8n** dans la barre latérale
    5. Cliquez sur "Enregistrer l'URL du webhook"
    6. Cliquez sur le bouton "Déclencher le workflow n8n" pour exécuter votre workflow
    """)

# Vérification de l'état de la connexion
with st.sidebar:
    if st.button("Vérifier la connexion n8n", key="check_connection"):
        try:
            # Vérifier si le serveur n8n est accessible
            base_url = webhook_url.split('/webhook/')[0]
            response = requests.get(f"{base_url}/healthz", timeout=5)
            if response.status_code == 200:
                st.success(f"✅ Le serveur n8n est accessible !")
            else:
                st.warning(f"⚠️ Le serveur n8n a retourné le code d'état : {response.status_code}")
        except requests.exceptions.RequestException as e:
            st.error(f"❌ Impossible de se connecter à n8n : {str(e)}")
            st.info("Assurez-vous que n8n est en cours d'exécution à l'URL correcte.")

# Afficher l'URL du webhook actuelle
st.caption(f"URL du webhook actuelle : {webhook_url}")
"@ | Out-File -FilePath $streamlitScript -Encoding utf8
    Write-Host "✅ Script Streamlit créé : $streamlitScript" -ForegroundColor Green
}
else {
    Write-Host "✅ Utilisation du script Streamlit existant : $streamlitScript" -ForegroundColor Green
}

# Vérifier si Node.js est installé pour la configuration de n8n
Write-Host "📋 Vérification de l'installation de Node.js..." -ForegroundColor Yellow
if (Test-CommandExists "node") {
    Write-Host "✅ Node.js est installé" -ForegroundColor Green
    
    # Vérifier la version de Node.js
    try {
        $nodeVersion = & node -v
        Write-Host "✅ Version de Node.js : $nodeVersion" -ForegroundColor Green
        
        # Vérifier si npm est installé
        if (Test-CommandExists "npm") {
            Write-Host "✅ npm est installé" -ForegroundColor Green
            
            # Vérifier si n8n est déjà installé
            $n8nPath = $null
            try {
                $n8nPath = (Get-Command n8n -ErrorAction SilentlyContinue).Path
            }
            catch {
                $n8nPath = $null
            }
            
            if ($n8nPath) {
                Write-Host "✅ n8n est déjà installé" -ForegroundColor Green
                try {
                    $n8nVersion = & n8n --version
                    Write-Host "✅ Version de n8n : $n8nVersion" -ForegroundColor Green
                }
                catch {
                    Write-Host "⚠️ Impossible de déterminer la version de n8n" -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "❌ n8n n'est pas installé" -ForegroundColor Red
                $installN8n = Read-Host "📥 Voulez-vous installer n8n globalement ? (o/n)"
                if ($installN8n -eq "o" -or $installN8n -eq "O" -or $installN8n -eq "y" -or $installN8n -eq "Y") {
                    Write-Host "📥 Installation de n8n globalement via npm..." -ForegroundColor Yellow
                    
                    try {
                        if ($isAdmin) {
                            npm install n8n -g
                        }
                        else {
                            Write-Host "⚠️ N'exécute pas en tant qu'administrateur. Vous devrez peut-être exécuter en tant qu'admin pour les installations npm globales." -ForegroundColor Yellow
                            $installAnyway = Read-Host "📥 Essayer d'installer quand même ? (o/n)"
                            if ($installAnyway -eq "o" -or $installAnyway -eq "O" -or $installAnyway -eq "y" -or $installAnyway -eq "Y") {
                                npm install n8n -g
                            }
                            else {
                                Write-Host "❌ Installation de n8n annulée." -ForegroundColor Red
                                exit
                            }
                        }
                        
                        # Vérifier si n8n est installé après l'installation
                        $n8nPathAfterInstall = (Get-Command n8n -ErrorAction SilentlyContinue).Path
                        if ($n8nPathAfterInstall) {
                            $n8nVersion = & n8n --version
                            Write-Host "✅ n8n installé avec succès ! Version : $n8nVersion" -ForegroundColor Green
                        }
                        else {
                            Write-Host "❌ L'installation de n8n a échoué." -ForegroundColor Red
                            Write-Host "ℹ️ Vous pourriez avoir besoin de permissions plus élevées pour installer des packages globaux." -ForegroundColor Yellow
                            Write-Host "ℹ️ Essayez d'exécuter ce script en tant qu'administrateur." -ForegroundColor Yellow
                            exit
                        }
                    }
                    catch {
                        Write-Host "❌ Erreur lors de l'installation de n8n: $_" -ForegroundColor Red
                        exit
                    }
                }
                else {
                    Write-Host "❌ n8n est nécessaire pour cette configuration." -ForegroundColor Red
                    exit
                }
            }
        }
        else {
            Write-Host "❌ npm n'est pas installé." -ForegroundColor Red
            Write-Host "ℹ️ Votre installation Node.js peut être incomplète ou corrompue." -ForegroundColor Yellow
            exit
        }
    }
    catch {
        Write-Host "❌ Erreur lors de la vérification de la version de Node.js: $_" -ForegroundColor Red
        exit
    }
}
else {
    Write-Host "❌ Node.js n'est pas installé." -ForegroundColor Red
    $installNode = Read-Host "📥 Installer Node.js maintenant ? (o/n)"
    if ($installNode -eq "o" -or $installNode -eq "O" -or $installNode -eq "y" -or $installNode -eq "Y") {
        Write-Host "📥 Ouverture de la page de téléchargement de Node.js..." -ForegroundColor Yellow
        Start-Process "https://nodejs.org/fr/download/"
        Write-Host "ℹ️ Veuillez installer la
