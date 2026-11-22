set shell := ["bash", "-euo", "pipefail", "-c"]

release_branch := "main"

# Show the version the next release would tag.
version:
    #!/usr/bin/env bash
    set -euo pipefail
    sed -n 's/^## \+//p' CHANGELOG.md | head -1

# Verify the tree is ready to tag a release.
check:
    #!/usr/bin/env bash
    set -euo pipefail
    fail() { echo "error: $1" >&2; exit 1; }

    version=$(sed -n 's/^## \+//p' CHANGELOG.md | head -1)
    [[ -n "$version" ]] || fail "no '## <version>' heading at the top of CHANGELOG.md"

    body=$(awk '/^## /{n++; next} n==1' CHANGELOG.md | grep -c '[^[:space:]]' || true)
    [[ "$body" -gt 0 ]] || fail "the $version changelog section is empty"

    branch=$(git branch --show-current)
    [[ "$branch" == "{{release_branch}}" ]] || fail "on '$branch', expected '{{release_branch}}'"

    git diff --quiet && git diff --cached --quiet || fail "working tree has uncommitted changes"

    ! git rev-parse -q --verify "refs/tags/v$version" >/dev/null || fail "tag v$version already exists locally"

    git fetch --quiet origin "{{release_branch}}"
    ! git ls-remote --exit-code --tags origin "v$version" >/dev/null 2>&1 || fail "tag v$version already exists on origin"
    git merge-base --is-ancestor HEAD "origin/{{release_branch}}" || fail "HEAD is not pushed to origin/{{release_branch}}"

    echo "ready to release v$version from $(git rev-parse --short HEAD)"

# Create the annotated release tag locally.
tag: check
    #!/usr/bin/env bash
    set -euo pipefail
    version=$(sed -n 's/^## \+//p' CHANGELOG.md | head -1)
    git tag -a "v$version" -m "v$version"
    echo "tagged v$version at $(git rev-parse --short HEAD)"

# Tag and push, which triggers the packager workflow.
release: tag
    #!/usr/bin/env bash
    set -euo pipefail
    version=$(sed -n 's/^## \+//p' CHANGELOG.md | head -1)
    git push origin "v$version"
    echo "pushed v$version — watch: gh run watch"

# Delete a local tag that has not been pushed.
untag version:
    #!/usr/bin/env bash
    set -euo pipefail
    if git ls-remote --exit-code --tags origin "v{{version}}" >/dev/null 2>&1; then
        echo "error: v{{version}} is already on origin; delete it there deliberately" >&2
        exit 1
    fi
    git tag -d "v{{version}}"
