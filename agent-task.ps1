# GAIA Agent Task Script mit Quality Gates
# Erstellt task-spezifische Sandbox für strukturierte Entwicklung

param(
    [Parameter(Mandatory=$true)]
    [string]$Task
)

# Konfiguration
$projectRoot = "C:\Projects\Gaia"
$coreDir = Join-Path $projectRoot "core"
$workDir = Join-Path $projectRoot "_work"
$scriptsDir = Join-Path $projectRoot "_scripts"

# Timestamp für eindeutige Benennung
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$sandboxName = "task-$Task-$timestamp"
$sandboxDir = Join-Path $workDir $sandboxName
$branchName = "agent/$Task-$timestamp"

Write-Host "`n=== GAIA AGENT TASK ===" -ForegroundColor Cyan
Write-Host "Task: $Task" -ForegroundColor Yellow
Write-Host "Sandbox: $sandboxDir" -ForegroundColor Yellow
Write-Host "Branch: $branchName" -ForegroundColor Yellow

# 1. Sandbox erstellen
Write-Host "`n[1/5] Erstelle Sandbox..." -ForegroundColor Cyan
if (!(Test-Path $workDir)) {
    New-Item -ItemType Directory -Path $workDir | Out-Null
}

# Kopiere core/ nach Sandbox
Copy-Item -Path $coreDir -Destination $sandboxDir -Recurse -Force
Write-Host "✓ Sandbox erstellt: $sandboxDir" -ForegroundColor Green

# 2. Git Branch erstellen
Write-Host "`n[2/5] Erstelle Git Branch..." -ForegroundColor Cyan
Push-Location $sandboxDir
try {
    git checkout -b $branchName 2>&1 | Out-Null
    Write-Host "✓ Branch erstellt: $branchName" -ForegroundColor Green
} catch {
    Write-Host "⚠ Branch-Erstellung fehlgeschlagen: $_" -ForegroundColor Yellow
} finally {
    Pop-Location
}

# 3. TASK.md erstellen
Write-Host "`n[3/5] Erstelle TASK.md..." -ForegroundColor Cyan
$taskContent = @"
# Task: $Task

**Erstellt:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Sandbox:** ``$sandboxDir``  
**Branch:** ``$branchName``

## Ziel

[Beschreibe hier das Ziel des Tasks]

## Anforderungen

- [ ] Anforderung 1
- [ ] Anforderung 2
- [ ] Anforderung 3

## Akzeptanzkriterien

- [ ] Funktionalität implementiert
- [ ] Tests geschrieben
- [ ] Dokumentation aktualisiert
- [ ] REPORT.md erstellt

## Notizen

[Ergänze hier wichtige Informationen]

---
*Generiert von GAIA Agent Task System*
"@

Set-Content -Path (Join-Path $sandboxDir "TASK.md") -Value $taskContent -Encoding UTF8
Write-Host "✓ TASK.md erstellt" -ForegroundColor Green

# 4. Claude Code starten
Write-Host "`n[4/5] Starte Claude Code..." -ForegroundColor Cyan
Write-Host "Arbeite in der Sandbox. Änderungen werden in Branch '$branchName' gespeichert." -ForegroundColor Yellow

Push-Location $sandboxDir
try {
    claude
} finally {
    Pop-Location
}

# 5. Quality Gates ausführen
Write-Host "`n[5/5] QUALITY GATES" -ForegroundColor Cyan
Write-Host "Starte automatische Qualitätsprüfung..." -ForegroundColor Yellow

$pythonCmd = if (Get-Command python -ErrorAction SilentlyContinue) { "python" } else { "python3" }

try {
    & $pythonCmd "$scriptsDir\quality-gates.py" $sandboxDir
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ QUALITY GATES BESTANDEN" -ForegroundColor Green
        Write-Host "Sandbox ist bereit für Review & Merge!" -ForegroundColor Green
    } else {
        Write-Host "`n❌ QUALITY GATES FEHLGESCHLAGEN" -ForegroundColor Red
        Write-Host "Bitte Fehler beheben vor Merge!" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Quality Gates konnten nicht ausgeführt werden: $_" -ForegroundColor Yellow
}

Write-Host "`n✓ Fertig! Sandbox: $sandboxDir" -ForegroundColor Green
Write-Host ""
