#!/bin/bash
# Пересобирает ветку next: свежий main плюс все открытые PR, которые встают без
# конфликта. Конфликтующие не молчат — печатаются с файлами, по которым спор.
# Разрешённые вручную слияния лежат в истории самой next; этот скрипт нужен,
# когда main уехал и всё надо сложить заново.
set -u
PRS="${*:-62 63 64 29 70 71 72 69 52}"
cd "$(dirname "$0")/../cyclop" || { echo "нет ./cyclop рядом"; exit 9; }
git fetch -q origin main 'refs/pull/*/head:refs/remotes/pr/*' --force
git checkout -q -B next origin/main
ok=(); bad=()
for n in $PRS; do
  if git merge -q --no-edit -m "PR #$n" "pr/$n" >/dev/null 2>&1; then ok+=("$n")
  else bad+=("$n: $(git diff --name-only --diff-filter=U | tr '\n' ' ')"); git merge --abort 2>/dev/null; fi
done
echo "встали:      ${ok[*]}"
printf 'конфликт:   %s\n' "${bad[@]:-нет}"
