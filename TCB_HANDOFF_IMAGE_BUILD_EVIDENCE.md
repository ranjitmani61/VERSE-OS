# TCB Handoff Image Build Evidence

Date: 2026-05-02

## Verdict

The injected TCB handoff capDL was compiled into a rebuilt capDL loader image.

This is stronger than parse-only evidence. The generated `capdl_spec.c` in the rebuilt image contains the ProcMan handoff slots.

This is still not runtime proof. The image has not yet been booted and ProcMan syscall success has not yet been observed.

## Build Result

Result marker:

`TCB_HANDOFF_IMAGE_V2_BUILD_OK`

Build warning still present:

`/usr/bin/ld: warning: kernel/kernel.elf has a LOAD segment with RWX permissions`

## Generated Image

Exported to:

`out/tcb_handoff_image_v2/capdl-loader-image-x86_64-pc99`

## ProcMan CNode Evidence

Generated `capdl_spec.c` contains:

- `256 / 0x100`: `CDL_TCBCap` to `testworker_testworker_0_control_tcb`
- `257 / 0x101`: read `CDL_EPCap` to `testworker_fault_ep`
- `258 / 0x102`: `CDL_CNodeCap` to `procman_cnode`
- `259 / 0x103`: `CDL_UntypedCap` to `verse_procman_tcb_untyped`
- `260 / 0x104`: absent / empty destination slot
- `261 / 0x105`: `CDL_CNodeCap` to `testworker_cnode`
- `262 / 0x106`: `CDL_PML4Cap` to `testworker_group_bin_pd`
- `263 / 0x107`: `CDL_FrameCap` to `testworker_frame__camkes_ipc_buffer_testworker_0_control`
- `264 / 0x108`: `CDL_EPCap` to `testworker_fault_ep`

## Strict Audit

`tools/check_tcb_handoff.py out/tcb_handoff_image_v2/verse_unified.cdl`

Result: PASS.

## Boundary

Not proven yet:

- Boot success for this modified image.
- ProcMan actually invokes the enforced path.
- `seL4_TCB_Suspend` succeeds.
- Runtime TCB retype/configure/write-registers/resume succeeds.
- Fresh TestWorker replacement works.

## Next Step

Boot `out/tcb_handoff_image_v2/capdl-loader-image-x86_64-pc99` and capture serial logs.
