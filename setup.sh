# Script PowerShell pour Windows

# Vérification et installation de Chocolatey
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey n'est pas installé. Installation de Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} else {
    Write-Host "Chocolatey est déjà installé."
}

# Vérification et installation de Python 3
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Python 3 n'est pas installé. Installation de Python 3..."
    choco install python -y
} else {
    Write-Host "Python 3 est déjà installé."
}

# Vérification et installation de Java 8
try {
    $javaVersion = & java -version 2>&1 | Select-Object -First 1
} catch {
    $javaVersion = ""
}
if ($javaVersion -notlike "*1.8*") {
    Write-Host "Java 8 n'est pas installé ou la version est incorrecte. Installation de Java 8..."
    choco install openjdk8 -y
} else {
    Write-Host "Java 8 est déjà installé."
}

# Vérification de l'existence de l'environnement virtuel
if (-not (Test-Path -Path ".\venv")) {
    Write-Host "Création d'un nouvel environnement virtuel..."
    python -m venv venv
} else {
    Write-Host "L'environnement virtuel existe déjà."
}

# Vérification et installation de Tesseract
if (-not (Get-Command tesseract -ErrorAction SilentlyContinue)) {
    Write-Host "Tesseract n'est pas installé. Installation de Tesseract..."
    choco install tesseract -y
} else {
    Write-Host "Tesseract est déjà installé."
}

# Configuration de la variable d'environnement TESSDATA_PREFIX
$TESSDATA_PREFIX = "$env:ProgramFiles\Tesseract-OCR"
[System.Environment]::SetEnvironmentVariable("TESSDATA_PREFIX", $TESSDATA_PREFIX, "Process")
Write-Host "La variable d'environnement TESSDATA_PREFIX a été définie sur : $TESSDATA_PREFIX"

# Vérification de l'installation de Tesseract et du fichier de langue français
if (-not (Test-Path "$TESSDATA_PREFIX\tessdata\fra.traineddata")) {
    Write-Host "Le fichier de langue français (fra.traineddata) est manquant. Téléchargement..."
    choco install tesseract-lang -y
} else {
    Write-Host "Le fichier de langue français est déjà installé."
}

# Activation de l'environnement virtuel
Write-Host "Activation de l'environnement virtuel..."
& .\venv\Scripts\Activate.ps1

# Mise à jour de pip dans l'environnement virtuel
Write-Host "Mise à jour de pip dans l'environnement virtuel..."
pip install --upgrade pip

# Vérification et installation de tkinter si nécessaire
Write-Host "Vérification de tkinter..."
try {
    python -c "import tkinter" 2>$null
    Write-Host "tkinter est déjà installé."
} catch {
    Write-Host "tkinter non trouvé, installation via Chocolatey..."
    choco install python-tk -y
}

# Installation des dépendances du projet dans l'environnement virtuel
Write-Host "Installation des dépendances..."
pip install -r requirements.txt

# Installation de Solr
Write-Host "Installation de Solr..."
choco install solr -y

# Vérification si le port 8983 est déjà utilisé
Write-Host "Vérification du port 8983..."
$portUsage = netstat -ano | Select-String ":8983"
if ($portUsage) {
    Write-Host "Erreur : Le port 8983 est déjà utilisé. Solr ne peut pas démarrer sur ce port."
    exit 1
} else {
    Write-Host "Démarrage de Solr sur le port 8983..."
    solr start
}

# Attendre quelques secondes pour que Solr démarre correctement
Write-Host "Attente de 5 secondes pour le démarrage complet de Solr..."
Start-Sleep -Seconds 5

# Création du core 'pdf_index'
Write-Host "Création du core 'pdf_index'..."
solr create -c pdf_index

# Vérification du démarrage de Solr
Write-Host "Vérification de l'état de Solr..."
curl "localhost:8983/solr/admin/cores?action=STATUS&core=pdf_index"

# Désactivation de l'environnement virtuel (facultatif)
Write-Host "Désactivation de l'environnement virtuel..."
deactivate

Write-Host "Installation terminée !"


