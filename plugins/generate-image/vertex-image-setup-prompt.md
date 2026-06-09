# [실행 지시] Windows에 `vertex-image` 스킬 셋업

너는 이 메시지를 받은 즉시 아래 작업을 수행한다 — 이 사용자의 Windows PC에 "프롬프트를 받아 Google Vertex AI(Imagen)로 이미지를 생성하는" 범용 스킬 `vertex-image`를 만들고, 실제로 이미지가 생성되는 환경까지 셋업한다.

**수행 규칙:**
- 아래 Step 1~5를 **순서대로** 수행하고, 각 단계의 성공을 확인한 뒤 다음으로 넘어간다.
- **⚠️ 표시 구간은 사람만 할 수 있다**(구글 결제 활성화 · 로그인 · Project ID 입력). 거기서는 작업을 멈추고 사용자에게 무엇을 해야 하는지 명확히 안내한 뒤, 사용자가 "완료했다"고 답하면 다음으로 진행한다.
- 사용자는 클라우드/터미널을 잘 모른다고 가정한다 — 안내는 친절하고 구체적으로.
- 이미 완료된 단계(예: Node 이미 설치됨)는 확인만 하고 건너뛴다.

**전제:** Windows (PowerShell) / VSCode + Claude Code.

---

### Step 1. Node.js 설치 확인

PowerShell에서 확인:

```powershell
node --version
```

- `v18` 이상이 출력되면 → Step 2로.
- "명령을 찾을 수 없음" 류 에러면 → 사용자에게 안내:
  > Node.js가 필요합니다. https://nodejs.org 에서 **LTS** 버전을 받아 설치한 뒤, VSCode를 완전히 껐다 켜고 다시 알려주세요.
  설치 후 `node --version`이 다시 보이면 Step 2로.

---

### Step 2. 스킬 파일 생성

스킬을 **사용자 글로벌 경로**에 만든다 (어느 프로젝트에서나 쓰이게):

```
%USERPROFILE%\.claude\skills\vertex-image\
```

아래 4개 파일을 **내용 그대로** 생성한다. (경로의 `~`/`%USERPROFILE%`는 실제 홈 디렉터리 — 보통 `C:\Users\<이름>`)

#### 2-1. `~/.claude/skills/vertex-image/SKILL.md`

````markdown
---
name: vertex-image
description: >
  Google Vertex AI(Imagen)로 이미지 1장 생성. 프롬프트를 받아 PNG로 저장.
  Vertex AI(ADC 인증) 기본, Gemini AI Studio(API key) 백엔드도 선택 가능.
  트리거: "이미지 만들어", "이미지 생성", "generate image", "mockup", "그려줘".
---

# vertex-image — Imagen 이미지 생성

## 한 줄 요약

PowerShell에서 `generate-mockup.mjs`를 호출해 이미지 1장을 생성한다. 기본 백엔드는 Vertex AI(ADC 자동 인증).

## 실행 커맨드

```powershell
node "$env:USERPROFILE\.claude\skills\vertex-image\scripts\generate-mockup.mjs" `
  --prompt "<영문 프롬프트>" `
  --output "<절대경로>.png" `
  --aspect-ratio "16:9" `
  --fast `
  --backend vertex
```

**타임아웃**: 120초

## 파라미터

| 파라미터 | 값 |
|---|---|
| `--prompt` | 영문 권장. 장면·스타일·구도 포함 |
| `--output` | 절대경로 `.png` (폴더 없으면 자동 생성) |
| `--aspect-ratio` | `16:9` `9:16` `1:1` `3:4` `4:3` |
| `--fast` | 붙이면 `imagen-4.0-fast-generate-001` (기본 권장, 빠름) |
| `--model` | 모델 직접 지정 (예: `imagen-4.0-ultra-generate-001`). 지정 시 `--fast` 무시 |
| `--backend` | `vertex`(기본, ADC 자동) 또는 `gemini`(`GEMINI_API_KEY` 필요) |

### 모델 선택

| 모델 | 플래그 | 특징 |
|---|---|---|
| `imagen-4.0-fast-generate-001` | `--fast` | 기본 권장. 빠르고 품질 충분 |
| `imagen-4.0-generate-001` | (없음) | 표준 품질 |
| `imagen-4.0-ultra-generate-001` | `--model ...` | 최고 품질, 느림 |

## 백엔드

| 백엔드 | 인증 | 비용 |
|---|---|---|
| `vertex` (기본) | ADC 자동 감지 — 환경변수 불필요 | GCP 크레딧 |
| `gemini` | `GEMINI_API_KEY` env var | AI Studio 할당량 |

## 인증 (Vertex)

- ADC 파일 자동 감지: `%APPDATA%\gcloud\application_default_credentials.json`
- `GOOGLE_CLOUD_PROJECT` 없어도 ADC 파일의 `quota_project_id` 자동 사용
- ADC 없으면 실패 → `scripts\setup-vertex-auth.ps1` 실행 안내

## 프롬프트 가이드

- **영문**으로, 장면·분위기·구도·스타일을 함께 묘사
- 예: `cozy coffee shop interior, warm morning light, wooden furniture, soft focus background, photorealistic`
- 추상적 단어보다 구체적 시각 요소를 나열할수록 결과가 안정적

## 출력

- 성공: stdout에 저장된 절대경로 1줄
- 실패: stderr에 에러 + exit code 1
````

#### 2-2. `~/.claude/skills/vertex-image/scripts/generate-mockup.mjs`

```javascript
#!/usr/bin/env node

/**
 * generate-mockup.mjs — Imagen 4 이미지 생성 (Vertex AI / Gemini)
 * Usage:
 *   node generate-mockup.mjs --prompt "..." --output "out.png" \
 *     [--aspect-ratio 16:9] [--fast] [--model ...] [--backend vertex|gemini]
 */

import { join, dirname, resolve } from 'path';
import { writeFileSync, mkdirSync, existsSync, readFileSync } from 'fs';
import { parseArgs } from 'util';
import { homedir } from 'os';

let GoogleGenAI;
try {
  ({ GoogleGenAI } = await import('@google/genai/node'));
} catch {
  console.error('@google/genai 미설치. 스킬 폴더(~/.claude/skills/vertex-image)에서 `npm install` 을 실행하세요.');
  process.exit(1);
}

const { values } = parseArgs({
  options: {
    prompt:         { type: 'string', short: 'p' },
    output:         { type: 'string', short: 'o' },
    'aspect-ratio': { type: 'string', default: '16:9' },
    fast:           { type: 'boolean', default: false },
    backend:        { type: 'string', default: 'vertex' },
    model:          { type: 'string' },
  },
  strict: true,
});

if (!values.prompt || !values.output) {
  console.error('Usage: node generate-mockup.mjs --prompt "..." --output "path.png" [--aspect-ratio 16:9] [--fast] [--backend vertex|gemini]');
  process.exit(1);
}

const backend = values.backend === 'gemini' ? 'gemini' : 'vertex';

let ai;
if (backend === 'gemini') {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error('GEMINI_API_KEY environment variable is required for --backend gemini');
    process.exit(1);
  }
  ai = new GoogleGenAI({ apiKey });
} else {
  // Vertex AI: project from env var or ADC file
  let projectId = process.env.GOOGLE_CLOUD_PROJECT;
  if (!projectId) {
    const adcPaths = [
      join(homedir(), 'AppData', 'Roaming', 'gcloud', 'application_default_credentials.json'),
      join(homedir(), '.config', 'gcloud', 'application_default_credentials.json'),
    ];
    for (const p of adcPaths) {
      try {
        if (existsSync(p)) {
          const adc = JSON.parse(readFileSync(p, 'utf-8'));
          if (adc.quota_project_id) { projectId = adc.quota_project_id; break; }
        }
      } catch {}
    }
  }
  if (!projectId) {
    console.error('No project ID found. Set GOOGLE_CLOUD_PROJECT or run: gcloud auth application-default login');
    process.exit(1);
  }
  const location = process.env.GOOGLE_CLOUD_LOCATION || 'us-central1';
  ai = new GoogleGenAI({ vertexai: true, project: projectId, location });
}

const outputPath = resolve(values.output);
const outputDir = dirname(outputPath);
if (!existsSync(outputDir)) mkdirSync(outputDir, { recursive: true });

const ASPECT_MAP = { '16:9': '16:9', '9:16': '9:16', '1:1': '1:1', '3:4': '3:4', '4:3': '4:3' };
const aspectRatio = ASPECT_MAP[values['aspect-ratio']] || '16:9';
const model = values.model || (values.fast ? 'imagen-4.0-fast-generate-001' : 'imagen-4.0-generate-001');

try {
  const response = await ai.models.generateImages({
    model,
    prompt: values.prompt,
    config: { numberOfImages: 1, aspectRatio },
  });

  const imageBytes = response.generatedImages?.[0]?.image?.imageBytes;
  if (!imageBytes) {
    console.error('No image in response.');
    process.exit(1);
  }

  writeFileSync(outputPath, Buffer.from(imageBytes, 'base64'));
  console.log(outputPath);
} catch (err) {
  console.error(`Generation failed: ${err.message}`);
  process.exit(1);
}
```

#### 2-3. `~/.claude/skills/vertex-image/scripts/setup-vertex-auth.ps1`

```powershell
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
```

#### 2-4. `~/.claude/skills/vertex-image/package.json`

```json
{
  "name": "vertex-image-skill",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "dependencies": {
    "@google/genai": "^1.0.0"
  }
}
```

#### 2-5. 의존성 설치

```powershell
cd "$env:USERPROFILE\.claude\skills\vertex-image"
npm install
```

`node_modules` 폴더가 생기면 성공.

---

### Step 3. Google Cloud 인증 셋업 (⚠️ 사람 개입 2군데)

스킬 폴더의 셋업 스크립트를 실행한다:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\skills\vertex-image\scripts\setup-vertex-auth.ps1"
```

이 스크립트는 자동으로: gcloud 설치 → 구글 로그인 → 프로젝트 설정 → Vertex AI API 활성화 → 환경변수 등록 까지 한다.

**다만 두 군데는 사람이 직접 해야 한다 (자동화 불가):**

> **⚠️ 사람이 직접 해야 하는 것 — 사용자에게 안내하세요:**
>
> **(A) 구글 클라우드 프로젝트 + 결제 계정 (최초 1회)**
> 1. https://console.cloud.google.com 접속, 구글 계정 로그인
> 2. 상단에서 **새 프로젝트** 생성 (이름 자유, 예: `my-image-gen`)
> 3. **결제 활성화** — 메뉴 → "결제(Billing)" → 결제 계정 연결. 신용카드 등록이 필요합니다.
>    - 신규 가입 시 **$300 무료 크레딧**이 제공되며, 그 안에서는 실제 청구되지 않습니다.
>    - 이미지 생성은 본인 프로젝트로 과금되므로 **각자 본인 계정**이 필요합니다 (남의 키를 받아쓰는 게 아닙니다).
> 4. 만든 프로젝트의 **Project ID**를 적어두세요 (스크립트가 물어봅니다).
>
> **(B) 스크립트 실행 중 두 번의 입력**
> - 브라우저가 열리면 → **구글 계정으로 로그인 + 권한 허용**
> - 터미널이 `Project ID`를 물으면 → 위에서 적어둔 **Project ID 입력**

스크립트가 "설정 완료"를 출력하면 → **VSCode(Claude Code)를 완전히 재시작**한다 (환경변수 반영).

---

### Step 4. 동작 검증

재시작 후, 테스트 이미지를 1장 생성한다:

```powershell
node "$env:USERPROFILE\.claude\skills\vertex-image\scripts\generate-mockup.mjs" `
  --prompt "a single red apple on a white table, soft studio light, photorealistic" `
  --output "$env:USERPROFILE\Desktop\vertex-test.png" `
  --aspect-ratio "1:1" `
  --fast `
  --backend vertex
```

- 성공: 바탕화면에 `vertex-test.png`가 생기고, stdout에 그 경로가 출력됨 → **셋업 완료** 🎉
- 실패 시 흔한 원인:
  | 에러 메시지 | 원인 / 해결 |
  |---|---|
  | `@google/genai 미설치` | Step 2-5의 `npm install`을 안 했음 |
  | `No project ID found` | Step 3 인증/프로젝트 설정 미완. setup-vertex-auth.ps1 다시 실행 |
  | `PERMISSION_DENIED` / `API ... disabled` | Vertex AI API 미활성 또는 결제 미연결. Console에서 결제 + API 확인 |
  | `quota` / `billing` 관련 | 결제 계정 미연결. 위 (A)-3 다시 확인 |

---

### Step 5. 이후 사용법

셋업이 끝나면, 사용자는 Claude에게 그냥 자연어로 요청하면 된다:

> "고양이가 창가에 앉아있는 이미지 만들어줘"

그러면 너(Claude)는 `vertex-image` 스킬의 실행 커맨드로 `generate-mockup.mjs`를 호출해 이미지를 생성하고, 저장 경로를 사용자에게 알려준다. 프롬프트는 영문으로 변환하고, 장면·분위기·구도를 구체적으로 묘사할수록 결과가 좋다.

---

## 부록: 비용/인증 한눈에

- **Vertex(기본)**: 각자 본인 구글 클라우드로 인증(ADC). 별도 API 키 불필요. 비용은 본인 프로젝트로 과금되며 신규 $300 무료 크레딧 적용.
- **Gemini(선택)**: `--backend gemini` + `GEMINI_API_KEY` 환경변수. 키는 https://aistudio.google.com 에서 본인이 무료 발급.
- 둘 다 **남의 키/크레딧을 공유받는 구조가 아니다** — 각 사용자가 본인 구글 계정으로 셋업한다.
