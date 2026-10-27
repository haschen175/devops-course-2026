#!/usr/bin/env bash
# Доставка статического ресурса на devops-vm
# Использование: scripts/deploy.sh [--dry-run]
set -euo pipefail

REMOTE="devops"
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="${HOME}/devops.crt"
REPO_ROOT="$(git rev-parse --show-toplevel)"
LOCAL_DIR="${REPO_ROOT}/site/"

# 1. Разбор аргумента --dry-run
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
elif [[ $# -gt 0 ]]; then
    echo "Ошибка: неизвестный аргумент '$1'. Использование: $0 [--dry-run]" >&2
    exit 1
fi

# 2. Проверки по требованиям 4 и 5
if [[ ! -f "${LOCAL_DIR}index.html" ]]; then
    echo "Ошибка: файл site/index.html отсутствует!" >&2
    exit 1
fi

if [[ -n "$(git -C "${REPO_ROOT}" status --porcelain)" ]]; then
    echo "Ошибка: в репозитории есть незафиксированные изменения!" >&2
    exit 1
fi

# 3. Синхронизация каталога
RSYNC_OPTS=(-avz --delete --chmod=D755,F644 -e "ssh -o BatchMode=yes -o ConnectTimeout=5")
if [[ "$DRY_RUN" == true ]]; then
    RSYNC_OPTS+=(--dry-run)
fi

rsync "${RSYNC_OPTS[@]}" "${LOCAL_DIR}" "${REMOTE}:${REMOTE_DIR}/"

# 4. При --dry-run завершение с кодом 0 без проверки доступности
if [[ "$DRY_RUN" == true ]]; then
    exit 0
fi

# 5. Проверка доступности ресурса и вывод короткого хеша коммита
if ! curl -fsS --cacert "${CA_CERT}" -o /dev/null "${SITE_URL}"; then
    echo "Ошибка: ресурс ${SITE_URL} недоступен или проверка сертификата не пройдена!" >&2
    exit 1
fi

echo "Деплой успешно завершён. Коммит: $(git -C "${REPO_ROOT}" rev-parse --short HEAD)"
exit 0
