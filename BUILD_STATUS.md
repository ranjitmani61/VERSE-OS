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
| BUILD-003 | PARTIAL | Command output from `./build.sh verse_unified` | `/usr/bin/ld: warning: kernel/kernel.elf has a LOAD segment with RWX permissions` | Build is successful but not clean/hardened. Do not claim hardened release until explained or fixed. | Investigate linker script/segment permissions and document whether this is expected for seL4 image format. |

## Build status

- Success/failure: PASS.
- Generated image path: `/tmp/camkes/build_verse_unified/images/capdl-loader-image-x86_64-pc99` inside the Docker container.
- Relevant warning: RWX LOAD segment on `kernel/kernel.elf`.
- Hardened build: NOT PROVEN.

