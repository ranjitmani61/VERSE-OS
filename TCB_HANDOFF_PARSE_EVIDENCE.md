# TCB Handoff parse-capDL Evidence

Date: 2026-05-02

## Verdict

The injected TCB handoff CDL parses through `parse-capDL` and generates a C capDL spec.

This advances the TCB path from offline text injection to accepted capDL tooling input.

This is still not runtime evidence. The image has not yet been rebuilt with this generated `capdl_spec_tcb_handoff.c`, booted, or tested for syscall success.

## Command Summary

The Docker build generated the normal CAmkES CDL, injected the handoff into a copy, and ran:

`./capDL-tool/parse-capDL --code capdl_spec_tcb_handoff.c --code-dynamic-alloc --object-sizes=capdl/object_sizes/object_sizes.yaml verse_unified_tcb_handoff.cdl`

Result:

`PARSE_CAPDL_TCB_HANDOFF_OK`

## Generated Outputs

Exported to `out/capdl_parse_tcb/`:

- `verse_unified.cdl`
- `verse_unified_tcb_handoff.cdl`
- `capdl_spec_tcb_handoff.c`

## Strict Audit

`tools/check_tcb_handoff.py out/capdl_parse_tcb/verse_unified_tcb_handoff.cdl` passes.

Required ProcMan slots found:

- `0x100`: `testworker_testworker_0_control_tcb`
- `0x101`: `testworker_fault_ep (R)`
- `0x102`: `procman_cnode (guard: 0, guard_size: 61)`
- `0x103`: `verse_procman_tcb_untyped`
- `0x105`: `testworker_cnode (guard: 0, guard_size: 61)`
- `0x106`: `testworker_group_bin_pd`
- `0x107`: `testworker_frame__camkes_ipc_buffer_testworker_0_control (RW)`
- `0x108`: `testworker_fault_ep (RWP)`

Required empty slot:

- `0x104`: empty destination slot for runtime `seL4_Untyped_Retype`

## Generated C Evidence

`capdl_spec_tcb_handoff.c` contains:

- `verse_procman_tcb_untyped`
- `testworker_testworker_0_control_tcb`
- `procman_cnode`
- ProcMan slot 256 / `0x100` as `CDL_TCBCap` to `testworker_testworker_0_control_tcb`
- ProcMan slot 257 / `0x101` as read `CDL_EPCap` to `testworker_fault_ep`
- ProcMan slot 258 / `0x102` as `CDL_CNodeCap` to `procman_cnode`
- ProcMan slot 259 / `0x103` as `CDL_UntypedCap` to `verse_procman_tcb_untyped`
- ProcMan slot 264 / `0x108` as `CDL_EPCap` to `testworker_fault_ep`

## Boundary

Not proven:

- The modified `capdl_spec_tcb_handoff.c` links into `capdl-loader`.
- The resulting image boots.
- ProcMan receives usable runtime authority.
- `seL4_TCB_Suspend`, `seL4_Untyped_Retype`, `seL4_TCB_Configure`, `seL4_TCB_WriteRegisters`, or `seL4_TCB_Resume` succeed.
- Fresh TestWorker TCB restart works.

## Next Step

Patch the Docker build flow experimentally so generated `capdl_spec.c` is replaced by the injected `capdl_spec_tcb_handoff.c`, then rebuild `capdl-loader` and the boot image.
