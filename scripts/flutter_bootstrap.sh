#!/bin/bash
# 只在 cloud session 跑;本地开发跳过
if [ "$CLAUDE_CODE_REMOTE" != "true" ]; then
  exit 0
fi

export PATH="/opt/flutter/bin:$PATH"

# 生成 web platform folder(repo 刻意不含 native folders)
if [ ! -d "web" ]; then
  flutter create --platforms=web --org com.example \
    --project-name anime_watchlist_app . >/dev/null 2>&1
  # 关键:flutter create 会覆盖 lib/ 和 pubspec.yaml,还原回 repo 版本
  git checkout -- lib/ pubspec.yaml
  git checkout -- test/ 2>/dev/null || true
fi

# .env — SUPABASE_* 在 hook 阶段才可用(setup script 阶段读不到)
if [ ! -f ".env" ]; then
  if [ -n "${SUPABASE_URL}" ] && [ -n "${SUPABASE_ANON_KEY}" ]; then
    printf 'SUPABASE_URL=%s\nSUPABASE_ANON_KEY=%s\n' \
      "${SUPABASE_URL}" "${SUPABASE_ANON_KEY}" > .env
  else
    touch .env    # 空 = demo mode
  fi
fi

flutter pub get >/dev/null 2>&1
exit 0
