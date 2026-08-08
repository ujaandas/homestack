default:
    @just --list

# Format
format:
    @echo "--- Formatting... ---"
    nix fmt
    @echo "--- Formatting complete! ---"

check:
    @echo "--- Running flake checks... ---"
    nix flake check
    @echo "--- Flake checks complete! ---"

test: format check
    @echo "--- All tests passed! ---"

update:
    @echo "Updating flake inputs..."
    nix flake update
    @echo "--- Flake inputs updated! ---"

build target:
    @echo "--- Building {{target}}... ---"
    nix build .#{{target}}
    @echo "--- Built {{target}}! --- "