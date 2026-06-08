# Zadanie: git bisect + Ansible

Konfigurujesz serwer WWW (nginx) na kontenerze-celu za pomocą Ansible. Repozytorium
z konfiguracją Ansible ma historię ~10 commitów — **jeden z nich psuje serwer**
(strona zwraca błąd HTTP, mimo że `ansible-playbook` kończy się sukcesem).

Twoje zadanie:

1. Uruchom kontenery i wdróż konfigurację — przekonaj się, że strona jest zepsuta.
2. Użyj **`git bisect`** (ręcznie), aby znaleźć commit, który wprowadził błąd.
3. Napraw błąd i potwierdź, że serwer znów działa.

Jedyny wymóg na maszynie: **Docker + Docker Compose**. Pełna instrukcja: [README.md](README.md).

Cel dydaktyczny: zielony przebieg Ansible **nie oznacza** działającego serwera —
trzeba weryfikować zachowanie, a `git bisect` pozwala szybko zlokalizować winny commit.
