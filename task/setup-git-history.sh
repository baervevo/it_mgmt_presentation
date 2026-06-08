#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
WS="workspace"
ROLE="$WS/roles/nginx"

rm -rf "$WS"
mkdir -p "$ROLE/tasks" "$ROLE/handlers" "$ROLE/templates"

cat > "$WS/inventory.ini" <<'EOF'
[web]
target ansible_host=target ansible_port=22

[web:vars]
ansible_user=deploy
ansible_ssh_private_key_file=/keys/id
ansible_python_interpreter=/usr/bin/python3
EOF

cat > "$WS/ansible.cfg" <<'EOF'
[defaults]
inventory = inventory.ini
host_key_checking = False
retry_files_enabled = False

[ssh_connection]
ssh_args = -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
EOF

git -C "$WS" init -q
git -C "$WS" config user.name  "Student Labu"
git -C "$WS" config user.email "student@example.com"
git -C "$WS" config commit.gpgsign false

STEP=0
commit_step() {
  STEP=$((STEP + 1))
  local d="2026-05-$(printf '%02d' $((9 + STEP)))T10:00:00"
  git -C "$WS" add -A
  GIT_AUTHOR_DATE="$d" GIT_COMMITTER_DATE="$d" \
    git -C "$WS" commit -q -m "$1"
  printf '   [%2d] %s\n' "$STEP" "$1"
}

cat > "$WS/.gitignore" <<'EOF'
*.retry
EOF

cat > "$WS/playbook.yml" <<'EOF'
---
- name: Konfiguracja serwera WWW
  hosts: web
  become: true
  roles:
    - nginx
EOF

write_tasks_min() {
  cat > "$ROLE/tasks/main.yml" <<'EOF'
---
- name: Aktualizacja indeksu pakietów
  ansible.builtin.apt:
    update_cache: true
EOF
}

write_tasks_full() {
  cat > "$ROLE/tasks/main.yml" <<'EOF'
---
- name: Aktualizacja indeksu pakietów
  ansible.builtin.apt:
    update_cache: true

- name: Instalacja nginx
  ansible.builtin.apt:
    name: nginx
    state: present

- name: Usunięcie domyślnej strony
  ansible.builtin.file:
    path: /etc/nginx/sites-enabled/default
    state: absent
  notify: reload nginx

- name: Konfiguracja serwera
  ansible.builtin.template:
    src: site.conf.j2
    dest: /etc/nginx/conf.d/site.conf
  notify: reload nginx

- name: Wdrożenie strony
  ansible.builtin.template:
    src: index.html.j2
    dest: /var/www/html/index.html
    mode: "0644"

- name: Sprawdzenie czy nginx działa
  ansible.builtin.shell: pgrep nginx
  register: nginx_proc
  changed_when: false
  failed_when: false

- name: Start nginx
  ansible.builtin.shell: nginx
  when: nginx_proc.rc != 0
EOF
}

write_handler() {
  cat > "$ROLE/handlers/main.yml" <<'EOF'
---
- name: reload nginx
  ansible.builtin.shell: nginx -t && nginx -s reload
EOF
}

write_index() {
  cat > "$ROLE/templates/index.html.j2" <<'EOF'
<!DOCTYPE html>
<html lang="pl">
<head>
  <meta charset="utf-8">
  <title>Serwer WWW</title>
</head>
<body>
  <h1>Serwer dziala OK</h1>
  <p>Strona wdrożona przez Ansible.</p>
</body>
</html>
EOF
}

NG_HEADER_COMMENT=""
NG_SERVER_NAME="_"
NG_XAPP=""
NG_GZIP=""
NG_CACHE=""
NG_SECHDR=""
NG_FOOTER_COMMENT=""
write_siteconf() {
  local root="$1"
  {
    if [ -n "$NG_HEADER_COMMENT" ]; then echo "$NG_HEADER_COMMENT"; fi
    echo "server {"
    echo "    listen 80 default_server;"
    echo "    server_name ${NG_SERVER_NAME};"
    echo ""
    echo "    root ${root};"
    echo "    index index.html;"
    if [ -n "$NG_XAPP" ];   then echo "    add_header X-App \"lab\" always;"; fi
    if [ -n "$NG_SECHDR" ]; then echo "    add_header X-Content-Type-Options nosniff always;"; fi
    if [ -n "$NG_GZIP" ];   then echo ""; echo "    gzip on;"; echo "    gzip_types text/html text/css;"; fi
    echo ""
    echo "    location / {"
    echo "        try_files \$uri \$uri/ =404;"
    echo "    }"
    if [ -n "$NG_CACHE" ]; then echo ""; echo "    location ~* \\.(css|js)\$ {"; echo "        expires 7d;"; echo "    }"; fi
    echo "}"
    if [ -n "$NG_FOOTER_COMMENT" ]; then echo "$NG_FOOTER_COMMENT"; fi
  } > "$ROLE/templates/site.conf.j2"
}

echo ">> Buduję historię commitów"

write_tasks_min
commit_step "init: szkielet roli ansible (nginx)"

write_tasks_full
write_handler
write_index
write_siteconf "/var/www/html"
commit_step "feat: dzialajacy serwer nginx ze strona"

NG_SERVER_NAME="lab.local _"
write_siteconf "/var/www/html"
commit_step "feat: nazwa serwera (server_name)"

NG_XAPP="1"
write_siteconf "/var/www/html"
commit_step "feat: naglowek X-App"

NG_GZIP="1"
write_siteconf "/var/www/html"
commit_step "feat: kompresja gzip"

NG_HEADER_COMMENT="# Konfiguracja serwera WWW laboratorium"
write_siteconf "/var/www/html"
commit_step "chore: komentarz w konfiguracji"

sed -i 's/mode: "0644"/mode: "0600"/' "$ROLE/tasks/main.yml"
commit_step "chore: zaostrzenie uprawnien pliku strony"

NG_CACHE="1"
write_siteconf "/var/www/html"
commit_step "feat: cache-control dla statyki"

NG_SECHDR="1"
write_siteconf "/var/www/html"
commit_step "feat: naglowek bezpieczenstwa"

NG_FOOTER_COMMENT="# koniec konfiguracji"
write_siteconf "/var/www/html"
commit_step "docs: komentarze koncowe"

echo ""
echo ">> Gotowe. Historia w $WS/ :"
git -C "$WS" --no-pager log --oneline

git -C "$WS" bundle create ../lab-repo.bundle --branches >/dev/null
echo ""
echo ">> Zapisano lab-repo.bundle"
echo "HEAD jest ZEPSUTY. Znany dobry commit: 'feat: dzialajacy serwer nginx ze strona'."
