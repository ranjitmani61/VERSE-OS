# BUILD_STATUS

Date: 2026-05-02

## Build command

```bash
./build.sh verse_unified
```

## Findings

| ID | Verdict | Evidence source | Exact quote or output excerpt | Implication | Required fix or next test |
|---|---|---|---|---|---|
| BUILD-001 | PASS | `build.sh:7-17` | `docker run --rm -v "$ROOT:/host" user_img-king`; `cp -a /host/src/apps/$APP`; `../init-build.sh -DPLATFORM=x86_64 -DSIMULATION=TRUE -DCAMKES_APP=$APP`; `echo BUILD_OK:$APP` | Canonical wrapper builds from `src/apps/$APP`. | Keep using `src/apps/verse_unified` as active app tree. |
| BUILD-002 | PASS | Command output from `./build.sh verse_unified` | `[357/357] Generating images/capdl-loader-image-x86_64-pc99`; `BUILD_OK:verse_unified` | Build completed and generated image inside Docker path `/tmp/camkes/build_verse_unified/images/capdl-loader-image-x86_64-pc99`. | Preserve full build logs for release artifacts. |
| BUILD-003 | DOCUMENTED_LIMITATION | `RWX_KERNEL_LOAD_SEGMENT_EVIDENCE.md`; `out/rwx_issue5_20260502_final/build.log` | `/usr/bin/ld: warning: kernel/kernel.elf has a LOAD segment with RWX permissions` | Build is successful but not clean/hardened. Kernel W^X is not proven. | Keep claim limited; do not claim hardened release unless the seL4 kernel linker/runtime mapping issue is fixed and re-proven. |

## Build status

- Success/failure: PASS.
- Generated image path: `/tmp/camkes/build_verse_unified/images/capdl-loader-image-x86_64-pc99` inside the Docker container.
- Relevant warning: RWX LOAD segment on `kernel/kernel.elf`; documented in `RWX_KERNEL_LOAD_SEGMENT_EVIDENCE.md`.
- Hardened build: NOT PROVEN.
