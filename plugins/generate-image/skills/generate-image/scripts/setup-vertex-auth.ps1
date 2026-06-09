# setup-vertex-auth.ps1
# Windows용 Vertex AI ADC 설정 스크립트
# Usage: powershell -ExecutionPolicy Bypass -File setup-vertex-auth.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== Vertex AI ADC Setup for Windows ===" -ForegroundColor Cyan

# 1. gcloud 설치 여부 확인
$gcloudCmd = $null
$commonPaths = @(
    "$env:LOCALAPPDATA\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd",
    "$env:ProgramFiles\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd",
    "C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
)
foreach ($p in $commonPaths) {
    if (Test-Path $p) { $gcloudCmd = $p; break }
}

if (-not $gcloudCmd) {
    Write-Host "`n[Step 1] Google Cloud SDK 설치 중..." -ForegroundColor Yellow
    $installerUrl = "https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe"
    $installerPath = "$env:TEMP\GoogleCloudSDKInstaller.exe"

    Write-Host "  다운로드: $installerUrl"
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
    Write-Host "  설치 실행 중... (브라우저 창 닫지 마세요)"
    Start-Process -FilePath $installerPath -ArgumentList "/S", "/allusers" -Wait
    Remove-Item $installerPath -ErrorAction SilentlyContinue

    # PATH 갱신
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

    foreach ($p in $commonPaths) {
        if (Test-Path $p) { $gcloudCmd = $p; break }
    }

    if (-not $gcloudCmd) {
        Write-Host "`n  [!] gcloud 설치 후 PATH에 없음. 새 터미널에서 다시 실행해주세요." -ForegroundColor Red
        exit 1
    }
    Write-Host "  gcloud 설치 완료: $gcloudCmd" -ForegroundColor Green
} else {
    Write-Host "[Step 1] gcloud 이미 설치됨: $gcloudCmd" -ForegroundColor Green
}

# 2. ADC 로그인
Write-Host "`n[Step 2] Google 계정 인증 (브라우저가 열립니다)..." -ForegroundColor Yellow
& $gcloudCmd auth application-default login

# 3. 프로젝트 설정
Write-Host "`n[Step 3] 사용할 Google Cloud 프로젝트 ID를 입력해주세요:" -ForegroundColor Yellow
Write-Host "  (Cloud Console URL에서 확인: console.cloud.google.com)"
$projectId = Read-Host "Project ID"

& $gcloudCmd config set project $projectId

# 4. Vertex AI API 활성화
Write-Host "`n[Step 4] Vertex AI API 활성화 중..." -ForegroundColor Yellow
& $gcloudCmd services enable aiplatform.googleapis.com --project $projectId

# 5. 환경변수 설정 (사용자 수준 — 영구)
[System.Environment]::SetEnvironmentVariable("GOOGLE_CLOUD_PROJECT", $projectId, "User")
[System.Environment]::SetEnvironmentVariable("GOOGLE_CLOUD_LOCATION", "us-central1", "User")
$env:GOOGLE_CLOUD_PROJECT = $projectId
$env:GOOGLE_CLOUD_LOCATION = "us-central1"

Write-Host "`n=== 설정 완료 ===" -ForegroundColor Green
Write-Host "  Project:  $projectId"
Write-Host "  Location: us-central1"
Write-Host "  ADC:      $env:APPDATA\gcloud\application_default_credentials.json"
Write-Host "`n이제 Claude Code를 재시작하면 이미지 생성이 작동합니다."
