set shell := ["bash", "-euo", "pipefail", "-c"]

default:
    @just --list

# run every cheap, local check
check: check-shell check-python

# parse shell scripts using the interpreter named in their shebang
check-shell:
    @while IFS= read -r file; do \
        case "$(head -n 1 "$file")" in \
            *bash*) bash -n "$file" ;; \
            *sh*) sh -n "$file" ;; \
        esac; \
    done < <(rg -l '^#!.*(/|\\s)(ba)?sh(\\s|$$)' bin scripts install)

# parse python without leaving __pycache__ behind
check-python:
    @python3 -c 'import ast, pathlib; [ast.parse(path.read_text(), filename=str(path)) for root in ("bin", "scripts", "install") for path in pathlib.Path(root).rglob("*.py")]'

# format shell scripts in place
fmt:
    @command -v shfmt >/dev/null || { echo 'fmt needs shfmt' >&2; exit 1; }
    @rg -l '^#!.*(/|\\s)(ba)?sh(\\s|$$)' bin scripts install | xargs shfmt -w
