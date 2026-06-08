Niezbędne pliki znajdziesz na [repozytorium](https://github.com/baervevo/it_mgmt_presentation/)

## Architektura

```
  docker compose up -d --build
  docker compose exec control bash      <- tu pracujesz
        │
        ▼
  ┌─ control ─────────────┐   SSH    ┌─ target ───────────────────┐
  │ Ansible + git + curl  │ ───────▶ │ sshd + nginx (z Ansible)   │
  │ ~/workspace (repo)    │   HTTP   │ :80                        │
  │ polecenia lab-*       │ ───────▶ │                            │
  └───────────────────────┘          └────────────────────────────┘
```

- **control** - środowisko pracy: ma Ansible, git i repo `~/workspace`.
- **target** - konfigurowany host.
- Repo `~/workspace` jest **montowane** z katalogu hosta `task/workspace` (przy
  pierwszym starcie odtwarzane z pakietu).

## Wymagania

- `docker` oraz `docker compose`.

## Start

Najprościej skryptem startowym (buduje kontenery i wchodzi do `control`):

- Linux/macOS: `./start.sh`
- Windows: `start.bat` (dwuklik lub w wierszu poleceń)

Równoważnie ręcznie:

```bash
cd task
docker compose up -d --build
docker compose exec control bash
```

Jesteś teraz w kontenerze **control**, w katalogu `~/workspace` - to repozytorium git
z konfiguracją Ansible.

Upewnij się, że jesteś na branchu `master`:

```bash
git checkout master
```

Wykonaj wdrożenie za pomocą Ansible:

```bash
ansible-playbook -i inventory.ini playbook.yml
```

Spróbuj odnieść wyświetlane logi do plików Ansible w katalogu `workspace` oraz `workspace/roles`.

Pomocnicze polecenia:

| polecenie    | działanie                                                       |
|--------------|-----------------------------------------------------------------|
| `lab-test`   | sprawdza serwer (`exit 0` = GOOD, `exit !=0` = BAD)             |
| `lab-reset`  | zatrzymuje nginx na target    |

## Krok 1: zobacz, że jest zepsute

```bash
ansible-playbook -i inventory.ini playbook.yml
lab-test
```

## Krok 2: znajdź znany dobry commit

```bash
git log --oneline
git checkout <sha>      # "feat: dzialajacy serwer nginx ze strona"
ansible-playbook -i inventory.ini playbook.yml && lab-test
```

## Krok 3: `git bisect`

```bash
git bisect start
git bisect bad  <sha_HEAD>     # ostatni commit jest zepsuty
git bisect good <sha_dobry>    # commit z kroku 2 działa
```

git ustawi Cię na commicie w środku zakresu. Dla **każdego** kroku:

```bash
ansible-playbook -i inventory.ini playbook.yml
lab-test
# jeśli TEST OK ->  git bisect good
# jeśli TEST FAIL -> git bisect bad
```

Powtarzaj, aż git wypisze: `<sha> is the first bad commit`.

> **Szybciej:** możesz zlecić bisectowi uruchamianie testu samemu -
> `git bisect run sh -c 'ansible-playbook -i inventory.ini playbook.yml >/dev/null && lab-test'`

## Krok 4: napraw

```bash
git bisect reset
git show <sha_pierwszego_zlego>
```

Popraw znaleziony błąd i dodaj commit zawierający naprawę błędu.

```bash
git commit -am "fix: poprawa konfiguracji ansible"
ansible-playbook -i inventory.ini playbook.yml && lab-test
```

## Sprzątanie

Wyjdź z kontenera (`exit`), a na hoście:

```bash
docker compose down -v  # zatrzymaj kontenery i usuń wolumin z kluczem
```

> Uwaga: repo żyje w katalogu hosta `task/workspace` (montowane), więc Twoja praca
> przetrwa `down`/`down -v`. Reset zadania od zera: usuń `task/workspace` i ponów
> `docker compose up -d` (repo odtworzy się z pakietu).
