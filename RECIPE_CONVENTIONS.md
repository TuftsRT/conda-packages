# Recipe Conventions

Every `recipe.yaml` in this repository must follow the structure below.
Most of what CI enforces - version format, version ordering, and
build-number monotonicity - is checked against the *built package's
own repodata*, not the recipe source, so a recipe can't skip this
structure to avoid those checks; it fails the same way either way.
The one piece that depends on actually following this structure is
`ci_tag`: nothing verifies it was wired into the build string, so a
recipe that omits it will still build and upload successfully, but
silently loses the guarantee that concurrent builds can't collide on
the same filename.

## Required structure

```yaml
context:
  version: "1.3.0"      # bumped by a human for a new upstream release
  build_number: 0         # bumped by a human for a packaging-only fix
  ci_tag: ${{ env.get("CI_TAG", default="") }}

package:
  name: <recipe-directory-name>
  version: ${{ version }}

build:
  number: ${{ build_number }}
  string: >-
    ${{ hash }}_${{ build_number }}${{ '_' ~ ci_tag if ci_tag else '' }}
```

## Why each piece exists

- **`version`** is always the clean upstream version, in every
  environment - CI never rewrites it. It's what `check-version-guard.sh`
  compares against what's already on the `dev`/`main` labels, and it
  must be a plain `MAJOR.MINOR.PATCH` triple (e.g. `1.3.0`) -
  `check-version-guard.sh` rejects anything else. This is the
  version-core subset of SemVer 2.0.0: real SemVer pre-release/build
  metadata syntax (`1.0.0-alpha`, `1.0.0+build`) is built on `-`/`+`,
  but a conda package version cannot contain a `-` at all - it would
  break parsing of the `name-version-buildstring` triple used
  throughout the conda ecosystem - so that part of the spec isn't
  usable here regardless of policy. Restricting to the version core
  also keeps `sort -V` (used for the ordering checks below) correct,
  since its ordering only breaks down on non-numeric, pre-release-style
  suffixes, which this format never contains.
- **`build_number`** is the mechanism for re-releasing an unchanged
  `version` after a packaging-only fix (a bad pin, a broken build
  script). CI requires it to strictly increase past whatever's already
  published for that version - see `check-version-guard.sh` and
  `promote-to-main.sh`.
- **Releases land in increasing version order, per package.** A
  version older than whatever's already on `main` can never be
  released - `check-version-guard.sh` rejects it at PR time and
  `promote-to-main.sh` rejects it again at release time, compared with
  `sort -V` (real version order, not string order) since `main` is
  never touched once a version ships. This is a deliberate limitation,
  not an oversight: this repository has no maintenance-branch model,
  and every package keeps exactly one `recipe.yaml` on `main`, so
  there's no way to carry an older version's state alongside current
  work without regressing `main`'s own history. There is accordingly
  no backport support - a fix always ships as a new, higher version.
  Once a version reaches `main`, `promote-to-main.sh` also deletes any
  build still sitting on `dev` for an older version of that package -
  under this ordering rule it could never legitimately release
  afterward, so it's dead weight, not history. `dev` is a staging
  area, not an archive; nothing should ever be pinned against it.
- **`ci_tag`** makes every CI run's output filename unique, without
  ever touching `version`. Without it, two builds of the same
  unbumped `version`/`build_number` - e.g. two open PRs that both
  still match what's on `main` - would render to the same filename
  and could overwrite each other's preview on Anaconda.org, even
  though they upload to different labels. CI sets the `CI_TAG`
  environment variable before invoking `rattler-build`:
  - PR builds: `pr<number>_<short-sha>` - a distinct filename per
    commit pushed to the PR, not just per PR (see `pr.yaml`). Every
    pushed commit keeps its own artifact under the `pr-<n>` label
    until the PR closes, rather than the latest push overwriting the
    last one. This trades a little storage for two things: a stale,
    slow-to-cancel run can never clobber a newer push's upload with
    older bytes, since they never share a filename; and any commit's
    exact preview build stays around for troubleshooting instead of
    being silently replaced. `upload-to-anaconda.sh` does not force
    these uploads - a conflict means something actually collided
    (e.g. a re-run racing a still-uploading prior attempt) and should
    fail loudly rather than silently pick a winner.
  - Manual/scratch builds: `gh_<branch-slug>`, derived from the
    branch dispatched from via `branch_slug()` in
    `_branch_slug.sh` (shared with `manual-build.yaml` and
    `cleanup-manual-builds.yaml`, so the label used to clean up a
    deleted branch always matches the one it was built under) -
    there's no free-text label input, so there's nothing for a human
    to mistype as `main` or `pr-<n>`. The slug appends a short hash
    of the raw branch name after sanitizing to alphanumerics, since
    sanitizing alone is many-to-one - `feature/foo`, `feature-foo`,
    and `feature.foo` would otherwise all collapse to the same label
    and silently overwrite each other's build. These *are*
    force-uploaded - redeploying to the same scratch slot on repeated
    dispatches from the same branch is the point of a manual build,
    unlike a PR preview. `upload-to-anaconda.sh` forces uploads
    specifically for the `gh-*` label prefix, nothing else.
  - A recipe built outside CI (e.g. locally) has no `CI_TAG` set, so
    `ci_tag` renders empty and the build string is unaffected - fine,
    since local builds are never uploaded through this pipeline.

`_` is used as the separator throughout because rattler-build build
strings cannot contain `-`.

`${{ hash }}` is rattler-build's variant hash, computed from the
recipe's build configuration (`target_platform` plus any unpinned,
variant-configured dependency) before the build runs - unrelated to,
and unaffected by, the archive-packing non-determinism that makes a
built package's own content SHA256 unreliable to compare across
rebuilds. For these recipes (no variant config, no unpinned variant
deps, fixed `win-64` platform) it's effectively constant.
