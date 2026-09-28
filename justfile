set shell := ["bash", "-euo", "pipefail", "-c"]

default:
    @just --list

# run every cheap, local check
check: check-shell check-python check-go check-web

# parse shell scripts using the interpreter named in their shebang
check-shell:
    @while IFS= read -r file; do \
        case "$(head -n 1 "$file")" in \
            *bash*) bash -n "$file" ;; \
            *sh*) sh -n "$file" ;; \
        esac; \
    done < <(rg -l '^#!.*(/|\\s)(ba)?sh(\\s|$$)' bin scripts install pi -g '!build/**' -g '!node_modules/**')

# parse python without leaving __pycache__ behind
check-python:
    @python3 -c 'import ast, pathlib; [ast.parse(path.read_text(), filename=str(path)) for root in ("bin", "scripts", "install", "pi") for path in pathlib.Path(root).rglob("*.py")]'

check-go:
    @for project in pi/services/io/server pi/services/io/share-server pi/services/io/dash-server; do \
        (cd "$project" && go vet ./...); \
    done

check-web:
    @for project in pi/services/io/web pi/services/io/share-web pi/services/io/dash-web; do \
        (cd "$project" && pnpm typecheck); \
    done

# format shell scripts in place
fmt:
    @command -v shfmt >/dev/null || { echo 'fmt needs shfmt' >&2; exit 1; }
    @rg -l '^#!.*(/|\\s)(ba)?sh(\\s|$$)' bin scripts install pi -g '!build/**' -g '!node_modules/**' | xargs shfmt -w
