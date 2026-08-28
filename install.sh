#!/usr/bin/env bash
# 원스토어 인앱결제 스킬을 AI 코딩 도구의 스킬 디렉토리에 설치한다.
#
# 사용법:
#   ./install.sh <안드로이드_프로젝트_경로>     프로젝트에 설치 (기본)
#   ./install.sh --user                        홈 디렉토리에 설치 (모든 프로젝트에서 사용)
#   ./install.sh --all <경로>                  더 많은 도구 디렉토리에 함께 설치
#   ./install.sh --dry-run <경로>              무엇을 어디에 복사할지만 출력
#   ./install.sh --force <경로>                설치본을 직접 고쳤더라도 덮어쓴다
#   ./install.sh --pull <경로>                 원격에서 최신을 받아온 뒤 설치한다
#   ./install.sh --offline <경로>              원격 확인을 건너뛴다
#
# 저장소가 뒤처졌는지 확인
#   설치 전에 원격을 fetch 해서(읽기 전용) 로컬이 뒤처졌으면 알린다. 자동으로 당기지는 않는다 —
#   로컬에 수정이 있을 수 있고, 설치와 동기화는 다른 일이다. 받아오려면 --pull 이나 git pull.
#
# 재설치·업데이트
#   설치할 때 `.install-manifest`(파일별 체크섬)를 함께 남긴다. 다시 실행하면 그것으로
#   "설치본을 사용자가 고쳤는지"를 판정한다.
#     손대지 않았다 → 조용히 갱신하거나 "이미 최신"
#     고쳤다        → 어떤 파일인지 알리고 중단한다. 덮어쓰려면 --force
#
# 기본 설치 위치는 세 곳이다.
#   .claude/skills/   Claude Code
#   .agents/skills/   Cursor · GitHub Copilot/VS Code · Gemini CLI · Codex 가 함께 읽는 공통 경로
#   .grok/skills/     Grok Build. 프로젝트 레벨에서는 .agents/ 를 읽지 않아 별도로 필요하다
#
# --all 은 여기에 .cursor/ .github/ .gemini/ .codex/ .junie/ 를 더한다.
# 도구가 자기 경로만 읽도록 설정돼 있을 때 쓴다.

set -uo pipefail
cd "$(dirname "$0")" || exit 1
SRC="$PWD/skills/onestore-iap"
SKILL_NAME="onestore-iap"

MANIFEST=".install-manifest"

# 설치본이 손대졌는지 판정하기 위한 지문. 매니페스트 자신은 제외한다.
fingerprint() {
  ( cd "$1" 2>/dev/null && find . -type f ! -name "$MANIFEST" -print0 | sort -z |
      xargs -0 shasum 2>/dev/null )
}

DRY=0
ALL=0
USER_SCOPE=0
FORCE=0
PULL=0
OFFLINE=0
TARGET=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --all)     ALL=1 ;;
    --user)    USER_SCOPE=1 ;;
    --force)   FORCE=1 ;;
    --pull)    PULL=1 ;;
    --offline) OFFLINE=1 ;;
    # 머리말 주석을 그대로 도움말로 쓴다. 줄 번호를 박아두면 주석이 늘 때 잘린다.
    -h|--help) awk 'NR>1 && /^#/ {sub(/^# ?/, ""); print; next} NR>1 {exit}' "$0"; exit 0 ;;
    -*)        echo "알 수 없는 옵션: $1"; exit 1 ;;
    *)         TARGET="$1" ;;
  esac
  shift
done

[ -d "$SRC" ] || { echo "스킬을 찾을 수 없습니다: $SRC"; exit 1; }

# 저장소가 원격보다 뒤처졌는지 확인한다. fetch 는 읽기 전용이라 워킹트리를 바꾸지 않는다.
check_upstream() {
  git rev-parse --git-dir >/dev/null 2>&1 || return 0          # git 저장소가 아니면 넘어간다
  git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1 || return 0 # 추적 브랜치가 없으면 넘어간다

  GIT_TERMINAL_PROMPT=0 git fetch --quiet 2>/dev/null || {
    echo "  원격 확인 실패 — 네트워크나 인증 문제일 수 있습니다. 로컬 사본으로 설치합니다."
    return 0
  }

  behind=$(git rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)
  [ "${behind:-0}" -eq 0 ] && return 0

  if [ "$PULL" -eq 1 ]; then
    echo "  원격에 새 커밋 ${behind}개 — 받아옵니다"
    if git pull --ff-only --quiet; then
      echo "  받아왔습니다: $(git log --oneline -1)"
    else
      echo "  받아오지 못했습니다 — 로컬에 수정이나 갈라진 커밋이 있습니다."
      echo "  직접 정리한 뒤 다시 실행하세요: git status / git pull"
      exit 1
    fi
  else
    echo "  ⚠ 저장소가 원격보다 ${behind}개 커밋 뒤처져 있습니다 — 예전 스킬이 설치됩니다"
    echo "     최신으로 설치하려면: ./install.sh --pull ${TARGET:-<경로>}"
    echo "     (또는 git pull 후 다시 실행)"
    echo
  fi
}

[ "$OFFLINE" -eq 0 ] && check_upstream

# 설치 기준 디렉토리 정하기
if [ "$USER_SCOPE" -eq 1 ]; then
  BASE="$HOME"
  SCOPE="개인 (모든 프로젝트)"
else
  BASE="${TARGET:-.}"
  BASE="$(cd "$BASE" 2>/dev/null && pwd)" || { echo "경로를 찾을 수 없습니다: ${TARGET:-.}"; exit 1; }
  SCOPE="프로젝트"

  if [ "$BASE" = "$PWD" ]; then
    echo "설치 대상이 스킬 저장소 자신입니다. 안드로이드 프로젝트 경로를 지정하세요."
    echo "  ./install.sh ~/AndroidStudioProjects/MyApp"
    exit 1
  fi

  # 안드로이드 프로젝트가 맞는지 가볍게 확인 (막지는 않는다)
  if ! ls "$BASE"/settings.gradle* >/dev/null 2>&1; then
    echo "참고: $BASE 에 settings.gradle 이 없습니다. 안드로이드 프로젝트 루트가 맞는지 확인하세요."
  fi
fi

# 설치할 디렉토리 목록
# .grok 은 프로젝트 레벨에서 .agents 를 읽지 않아 별도로 넣는다(홈에서는 ~/.agents 도 읽는다).
DIRS=".claude .agents .grok"
[ "$ALL" -eq 1 ] && DIRS="$DIRS .cursor .github .gemini .codex .junie"

echo "== 원스토어 인앱결제 스킬 설치 =="
echo "  원본: $SRC"
echo "  대상: $BASE  ($SCOPE)"
echo

FAIL=0
for d in $DIRS; do
  dest="$BASE/$d/skills"
  if [ "$DRY" -eq 1 ]; then
    if [ -d "$dest/$SKILL_NAME" ]; then
      echo "  [예정] $d/skills/$SKILL_NAME  (기존 설치를 덮어씀)"
    else
      echo "  [예정] $d/skills/$SKILL_NAME"
    fi
    continue
  fi

  mkdir -p "$dest" || { FAIL=1; continue; }
  installed="$dest/$SKILL_NAME"

  if [ -d "$installed" ]; then
    if diff -rq --exclude="$MANIFEST" "$SRC" "$installed" >/dev/null 2>&1; then
      echo "  = $d/skills/$SKILL_NAME  (이미 최신)"
      continue
    fi

    # 설치본이 손대졌는지 판정한다 — 설치 시점 지문과 지금 상태를 비교한다.
    edited=""
    if [ -f "$installed/$MANIFEST" ]; then
      changed=$(diff <(cat "$installed/$MANIFEST") <(fingerprint "$installed") 2>/dev/null |
                  grep '^[<>]' | awk '{print $NF}' | sort -u | sed 's|^\./||')
      [ -n "$changed" ] && edited="$changed"
    else
      # 예전 방식이나 손으로 복사한 설치본 — 손댔는지 판정할 근거가 없다.
      edited="(설치 기록이 없어 판정 불가)"
    fi

    if [ -n "$edited" ] && [ "$FORCE" -eq 0 ]; then
      echo "  ! $d/skills/$SKILL_NAME  — 설치본이 원본과 다르고, 직접 고친 흔적이 있습니다"
      echo "$edited" | sed 's/^/        /'
      echo "        덮어쓰려면 --force. 먼저 백업하거나 원본에 반영하는 것을 권합니다"
      FAIL=1
      continue
    fi

    rm -rf "${dest:?}/$SKILL_NAME"
    action=$([ -n "$edited" ] && echo "덮어씀 (--force)" || echo "갱신")
  else
    action="설치"
  fi

  if cp -R "$SRC" "$dest/"; then
    ( cd "$installed" && fingerprint . > "$MANIFEST" )
    echo "  + $d/skills/$SKILL_NAME  ($action)"
  else
    FAIL=1
  fi
done

[ "$DRY" -eq 1 ] && { echo; echo "실제로 복사하지 않았습니다 (--dry-run)"; exit 0; }
[ "$FAIL" -ne 0 ] && { echo; echo "설치 중 오류가 발생했습니다"; exit 1; }

# 설치 확인
check="$BASE/.claude/skills/$SKILL_NAME/SKILL.md"
if [ -f "$check" ]; then
  name=$(awk -F': *' '/^name:/{print $2; exit}' "$check")
  echo
  echo "설치 완료 — 스킬 이름: $name"
  echo
  cat <<'GUIDE'
쓰는 법 — 그 프로젝트에서 AI 코딩 도구를 열고 자연어로 물어보면 됩니다.
         스킬 이름을 부르지 않아도 걸립니다.

  "지금 원스토어 결제 설정이 어디까지 됐어?"   상태 진단 (파일을 고치지 않습니다)
  "원스토어 인앱결제 붙여줘"                   의존성·매니페스트·결제 코드 배치
  "responseCode 7이 뜨는데 왜 그래?"           오류 진단 — 원인·수정 코드

  할 수 있는 일 전체는 이렇게 물으면 알려줍니다 — "원스토어 결제 스킬로 뭘 할 수 있어?"
  설치 경로·업데이트·옵션은 README.md 를 보세요.
GUIDE
else
  echo
  echo "설치를 확인하지 못했습니다: $check"
  exit 1
fi
