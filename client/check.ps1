# Quick Flutter client health check (run after git pull).
# Usage: cd client; .\check.ps1

$ErrorActionPreference = "Stop"

Write-Host "== Apex client check ==" -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: flutter not found in PATH." -ForegroundColor Red
    Write-Host "Install Flutter and reopen PowerShell, or add flutter\bin to PATH."
    exit 1
}

Write-Host "`n-- flutter --version --"
flutter --version

$dartVersion = (flutter --version | Select-String "Dart (\S+)" | ForEach-Object { $_.Matches.Groups[1].Value })
if ($dartVersion) {
    $dartMajorMinor = [version]($dartVersion -replace '(\d+\.\d+).*', '$1')
    if ($dartMajorMinor -lt [version]"3.9") {
        Write-Host "`nWARNING: Dart $dartVersion is too old for go_router 17.x (needs Dart 3.9+)." -ForegroundColor Yellow
        Write-Host "Run: flutter upgrade"
    }
}

Write-Host "`n-- flutter pub get --"
flutter pub get

Write-Host "`n-- flutter analyze --"
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "Analyze reported issues (see above)." -ForegroundColor Yellow
}

Write-Host "`n-- flutter test --"
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "Tests failed." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "`nOK: client is ready. Start backend first, then:" -ForegroundColor Green
Write-Host "flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8080"
