# 이 폴더를 깃허브 페이지로 올린다 — OAuth 프로덕션 전환에 필요한 두 주소를 만든다.
#
#   1) 먼저 로그인한다 (브라우저가 열린다. 사람이 직접 해야 한다)
#        gh auth login
#   2) 그 다음 이것을 돌린다
#        powershell -ExecutionPolicy Bypass -File "...\site\올리기.ps1"
#
# 저장소 이름은 <아이디>.github.io 여야 한다. 그래야 주소가
# https://<아이디>.github.io/ 로 짧게 나온다 (하위 폴더가 안 붙는다).

# git·gh 는 보통 메시지도 stderr 로 뱉는다. Stop 이면 경고 한 줄에 멈춘다.
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── 로그인 확인
$who = (& gh api user --jq .login) 2>$null
if (-not $who) {
  Write-Host "깃허브에 로그인되어 있지 않다. 먼저 이것부터:" -ForegroundColor Yellow
  Write-Host "  gh auth login"
  exit 1
}
$repo = "$who.github.io"
Write-Host "계정: $who" -ForegroundColor Green
Write-Host "저장소: $repo"

# ── 로컬 저장소 준비
Set-Location $here
if (-not (Test-Path ".git")) {
  & git init -b main | Out-Null
  Write-Host "  git 저장소 만듦"
}
& git add -A
$변경 = (& git status --porcelain)
if ($변경) {
  & git commit -q -m "shorts-upload 홈페이지와 개인정보처리방침"
  Write-Host "  커밋함"
} else {
  Write-Host "  바뀐 것 없음"
}

# ── 원격 저장소 (없으면 만든다)
$있나 = (& gh repo view "$who/$repo" --json name) 2>$null
if (-not $있나) {
  & gh repo create $repo --public --source=. --remote=origin --push
  Write-Host "  저장소를 만들고 올렸다" -ForegroundColor Green
} else {
  $원격 = (& git remote) -join " "
  if ($원격 -notmatch "origin") { & git remote add origin "https://github.com/$who/$repo.git" }
  & git push -u origin main
  Write-Host "  올렸다" -ForegroundColor Green
}

# ── 페이지 켜기 (이미 켜져 있으면 조용히 넘어간다)
try {
  & gh api -X POST "repos/$who/$repo/pages" -f "source[branch]=main" -f "source[path]=/" | Out-Null
  Write-Host "  깃허브 페이지 켬"
} catch {
  Write-Host "  페이지는 이미 켜져 있는 듯하다"
}

Write-Host ""
Write-Host "주소 (반영까지 1~2분 걸린다):" -ForegroundColor Green
Write-Host "  홈페이지          https://$who.github.io/"
Write-Host "  개인정보처리방침  https://$who.github.io/privacy.html"
Write-Host "  이용약관          https://$who.github.io/terms.html"
Write-Host ""
Write-Host "다음: 구글 클라우드 콘솔 > 브랜딩 에 위 두 주소를 넣고,"
Write-Host "      대상 > 앱 게시 > 프로덕션으로 푸시 를 누른다."
