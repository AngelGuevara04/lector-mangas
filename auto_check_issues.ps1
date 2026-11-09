# Script de verificacion y notificacion automatica de incidencias para AppParaMiAmors
$ErrorActionPreference = "SilentlyContinue"

$repo = "AngelGuevara04/lector-mangas"
$workspace = "C:\Users\ajgm1\Desktop\Amors"
$conversationId = "dcdbd38a-96bf-4b8d-bdbd-6c48ce7391c7"
$undeliveredDir = "C:\Users\ajgm1\.gemini\antigravity\brain\$conversationId\.system_generated\messages\undelivered"
$logFile = "$workspace\auto_resolver_incidencias.log"
$antigravityExe = "C:\Users\ajgm1\AppData\Local\Programs\antigravity\Antigravity.exe"
$dockerExe = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
$supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxdmx3Y3FmanFydWtndndmaG5oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI5MjQ5MzYsImV4cCI6MjA5ODUwMDkzNn0.F1AYU6R5ri3DnZEdfsHA9dTRbZXEpNdjalZWd5nfWp8"

# 1. Consultar incidencias abiertas en GitHub
$ghIssues = @()
try {
    $ghRaw = gh issue list --repo $repo --state open --json number,title,body 2>$null | ConvertFrom-Json
    if ($ghRaw) {
        $ghIssues = $ghRaw
    }
} catch {}

# 2. Consultar reportes pendientes en Supabase (enviados directo desde la app)
$dbIssues = @()
try {
    $headers = @{
        "apikey" = $supabaseKey
        "Authorization" = "Bearer $supabaseKey"
    }
    $url = "https://pqvlwcqfjqrukgvwfhnh.supabase.co/rest/v1/app_suggestions?select=id,type,message,status,created_at&status=eq.pending&or=(message.ilike.*AppParaMiAmors*,type.eq.capitulo_caido)"
    $res = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
    if ($res) {
        if ($res -is [System.Array]) {
            $dbIssues = $res
        } else {
            $dbIssues = @($res)
        }
    }
} catch {}

# Si no hay incidencias pendientes, salir silenciosamente sin abrir nada
if ($ghIssues.Count -eq 0 -and $dbIssues.Count -eq 0) {
    Write-Output "[OK] No hay incidencias abiertas ni en GitHub ni en Supabase."
    exit 0
}

$dateStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logFile -Value "========================================================================="
Add-Content -Path $logFile -Value "[$dateStr] INCIDENCIAS DETECTADAS"
Add-Content -Path $logFile -Value "GitHub: $($ghIssues.Count) abiertas | Supabase: $($dbIssues.Count) pendientes"
Add-Content -Path $logFile -Value "========================================================================="

# Construir resumen del mensaje para Antigravity
$reportText = "[ALERTA DE INCIDENCIAS PARA RESOLVER]`r`n`r`n"

if ($ghIssues.Count -gt 0) {
    $reportText += "### Incidencias abiertas en GitHub ($($ghIssues.Count)):`r`n"
    foreach ($issue in $ghIssues) {
        $reportText += "- #$($issue.number) - $($issue.title)`r`n  $($issue.body)`r`n"
        Add-Content -Path $logFile -Value "[GitHub #$($issue.number)] $($issue.title)"
    }
    $reportText += "`r`n"
}

if ($dbIssues.Count -gt 0) {
    $reportText += "### Reportes directos desde la App en Supabase ($($dbIssues.Count)):`r`n"
    foreach ($dbItem in $dbIssues) {
        $reportText += "- ID: $($dbItem.id) | Tipo: $($dbItem.type)`r`n  $($dbItem.message)`r`n"
        Add-Content -Path $logFile -Value "[Supabase $($dbItem.id)] $($dbItem.type): $($dbItem.message)"
    }
    $reportText += "`r`n"
}

$reportText += @"
PASOS DE AUTO-RESOLUCION:
1. Analiza cada incidencia y aplica la solucion o mejora en el codigo fuente de Flutter en C:\Users\ajgm1\Desktop\Amors\desarrollo.
2. Verifica compilacion con dart analyze lib y flutter test.
3. Incrementa la version en pubspec.yaml y update_service.dart.
4. Compila el nuevo APK ejecutando compilar_apk.bat.
5. Haz commit y push a GitHub (git add ., git commit, git push origin main).
6. Publica la release en GitHub Releases con gh release create adjuntando AppParaMiAmors.apk.
7. Si son incidencias de GitHub, cierralas con gh issue close. Si son de Supabase, actualiza su status a 'completed'.
8. Al terminar, CIERRA TODOS los procesos y ventanas utilizados (Docker si se abrio, y Antigravity con taskkill /F /IM Antigravity.exe /T).
"@

# 3. Escribir mensaje en la bandeja undelivered de esta conversacion de Antigravity
if (!(Test-Path $undeliveredDir)) {
    New-Item -ItemType Directory -Force -Path $undeliveredDir | Out-Null
}

$msgGuid = [System.Guid]::NewGuid().ToString()
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$messageJson = @{
    id = $msgGuid
    recipient = $conversationId
    sender = "system"
    priority = "MESSAGE_PRIORITY_HIGH"
    timestamp = $timestamp
    hideFromUser = $false
    content = $reportText
} | ConvertTo-Json -Compress

[System.IO.File]::WriteAllText("$undeliveredDir\$msgGuid.json", $messageJson, [System.Text.Encoding]::UTF8)

# 4. Asegurarse de que Docker se inicie si es necesario
try {
    docker info 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0 -and (Test-Path $dockerExe)) {
        Start-Process $dockerExe
        Start-Sleep -Seconds 5
    }
} catch {}

# 5. Abrir la ventana de Antigravity en el workspace
if (Test-Path $antigravityExe) {
    Start-Process $antigravityExe -ArgumentList "`"$workspace`""
}

Write-Output "[OK] Incidencias enviadas a la conversacion de Antigravity."
exit 0
