# VERSE OS capDL TCB Handoff Integration

Status: implementation started. This document describes the native seL4/CAmkES path required to turn `src/capdl/verse_tcb_handoff.cdl` into a runnable enforced restart path. The current Docker CAmkES image still runs the cooperative fallback unless `VERSE_TCB_ENFORCED` is explicitly enabled in a native build that provides the caps.

## Current Fact

The Ubuntu 24.04 manifest sync completed, but the checked CAmkES revision does not provide a built-in `seL4TCB` connector. The generated templates create TCB objects and per-component fault endpoints internally, but there is no connector that gives ProcMan a capability to TestWorker's TCB.

## Handoff Contract

The overlay reserves the following ProcMan CSpace slots:

- `0x100`: TestWorker TCB capability, used as `VERSE_WORKER_TCB_CPTR`.
- `0x101`: ProcMan receive capability for the TestWorker fault endpoint, intended as `VERSE_WORKER_FAULT_EP_CPTR`.
- `0x102`: ProcMan CNode cap, used as the destination root for `seL4_Untyped_Retype`.
- `0x103`: untyped cap large enough for one TCB object.
- `0x104`: empty ProcMan CNode slot where the fresh TCB cap is created.
- `0x105`: TestWorker CSpace root cap for `seL4_TCB_Configure`.
- `0x106`: TestWorker VSpace root cap for `seL4_TCB_Configure`.
- `0x107`: TestWorker IPC buffer frame cap for `seL4_TCB_Configure`.
- `0x108`: TestWorker fault endpoint cap for `seL4_TCB_Configure`.

The overlay routes TestWorker faults by setting TestWorker's TCB fault endpoint CPtr to `0x2` and placing a badged cap to `procman_fault_ep` in TestWorker's CNode slot `0x2`.

## ProcMan Syscall Cap Requirements

- `seL4_TCB_Suspend(worker_tcb)`: ProcMan needs `0x100`, a cap to the currently running TestWorker TCB.
- `seL4_Untyped_Retype(untyped, seL4_TCBObject, ...)`: ProcMan needs `0x103`, plus a destination CNode cap at `0x102`, and empty destination slot `0x104`.
- `seL4_TCB_Configure(fresh_tcb, ...)`: ProcMan needs the fresh TCB cap in `0x104`, worker CSpace cap `0x105`, worker VSpace cap `0x106`, worker IPC buffer frame `0x107`, and worker fault endpoint `0x108`.
- `seL4_TCB_WriteRegisters(fresh_tcb, ...)`: ProcMan needs the fresh TCB cap `0x104` and correct entry point/stack metadata from the generated CAmkES ELF/linker output.
- `seL4_TCB_Resume(fresh_tcb)`: ProcMan needs the fresh TCB cap `0x104`.

For MCS kernels, ProcMan also needs a scheduling context cap and scheduling authority for `seL4_TCB_SetSchedParams`; those are not in the current non-MCS x86_64 overlay and must be added if the native build uses MCS.

## CAmkES-capDL Merge Strategy

CAmkES generates the final system capDL from its assembly, templates, ELF metadata, and allocator state. `src/capdl/verse_tcb_handoff.cdl` is therefore not a replacement for the generated `system.cdl`/final capDL file; it is an overlay contract.

The merge must happen after CAmkES has generated its capDL and before `capDLToolCFileGen` converts the final capDL into `capdl_spec.c`:

1. Generate the normal CAmkES capDL for `verse_unified`.
2. Locate generated object names for ProcMan CNode, TestWorker control TCB, TestWorker CNode, TestWorker VSpace root, TestWorker IPC buffer frame, and TestWorker fault endpoint.
3. Rewrite the overlay names to those generated object names.
4. Insert the additional ProcMan CNode slots listed in the handoff contract.
5. Ensure slot `0x104` is empty at boot; it is the runtime destination for `seL4_Untyped_Retype`.
6. Regenerate `capdl_spec.c` from the merged capDL and rebuild the capDL loader image.

I checked the synced `camkes.runner` arguments and `camkes-gen.cmake` templates for an `--extra-cdl` style option. This CAmkES revision does not expose a direct `--extra-cdl` switch in the runner argument parser. The practical paths are:

- Manual post-processing: add a CMake step between the generated capDL target and `CapDLToolCFileGen` that runs a merge script over the generated capDL.
- Template patch: patch `camkes/templates/component.common.c` or the capDL generation template to emit the extra ProcMan slots directly when a VERSE-specific option is enabled.
- Python allocator hook: extend the CAmkES runner/capDL allocator path so the additional caps are added before `object-final.pickle` and final capDL rendering.

Manual post-processing is the least invasive first path, but it must be validated by parsing the merged capDL and diffing the authority graph.

## Custom Connector Alternative

A custom CAmkES connector is possible, but it is not "pure assembly only." It would require connector definition, templates, and allocator support that explicitly allocate or copy a TCB cap from the TestWorker object into ProcMan's CSpace. That is cleaner long-term than a text merge because the authority appears in the CAmkES model, but it is more invasive:

- define a connector such as `seL4TCBHandoff`;
- add templates that can reference the target component's generated TCB object;
- allocate a ProcMan-side CSpace slot and copy the TCB cap there;
- add optional fault endpoint routing;
- update the capability audit expected graph.

Given the current revision has no stock `seL4TCB` connector, the near-term implementation should use capDL post-processing, then move to a connector/template patch once the slot contract is proven.

## Integration Steps

1. Build `verse_unified` in the native CAmkES tree and preserve the generated capDL output.
2. Identify the generated names for ProcMan's CNode, TestWorker's control TCB, TestWorker's CNode, IPC buffer frame, VSpace root, and existing TestWorker fault endpoint.
3. Apply the overlay semantics from `src/capdl/verse_tcb_handoff.cdl` to the generated spec:
   - copy the TestWorker TCB cap into ProcMan CNode slot `0x100`;
   - ensure ProcMan has a receive cap for the worker fault endpoint in slot `0x101`;
   - set TestWorker's TCB fault endpoint to the worker CSpace slot that contains the badged ProcMan fault endpoint cap;
   - preserve TestWorker's normal CSpace, VSpace, IPC buffer, scheduling context, and existing CAmkES caps.
4. Compile the native build with the enforced path enabled. In this CAmkES tree, `DeclareCAmkESComponent(ProcMan ...)` does not expose a plain CMake target named `ProcMan`, so a direct `target_compile_definitions(ProcMan ...)` is not valid. Use a scoped app-level definition, or attach the definitions to the generated component target after confirming its exact name:

```cmake
add_compile_definitions(
    VERSE_TCB_ENFORCED
    VERSE_WORKER_TCB_CPTR=0x100
    VERSE_WORKER_FAULT_EP_CPTR=0x101)
```

5. Boot the native image and verify that ProcMan can call `seL4_TCB_Suspend(worker_tcb)` without `seL4_InvalidCapability`.
6. Replace the current restart stub with real resource teardown:
   - suspend TestWorker TCB;
   - revoke or delete the managed CSpace/VSpace slots;
   - rebuild the worker address space from a known-good template;
   - configure IPC buffer, scheduling context, registers, fault endpoint, and entry point;
   - resume the fresh TCB.
7. Extend `tools/capability_audit.py` so ProcMan authority over TestWorker is expected only for the exact slots above, and so no unrelated TCB caps are granted.

## Validation Gates

The enforced path is not complete until a QEMU/native log shows all of:

```text
ProcMan: seL4_TCB_Suspend(worker_tcb) OK
ProcMan: resource revoke/teardown OK
ProcMan: fresh TestWorker TCB configured
ProcMan: fresh TestWorker TCB resumed
TestWorker: started fresh instance
```

Until then, the runtime claim remains: cooperative restart is working, and TCB-enforced restart is under implementation.

## Compile Probe

The default `verse_unified` build still compiles without `VERSE_TCB_ENFORCED`. A temporary Docker build copy was also compiled with app-level `add_compile_definitions(VERSE_TCB_ENFORCED ...)`; `procman.instance.bin` linked successfully. That verifies the guarded syscall path is syntactically compatible with the current seL4 headers, but it does not prove runtime capability availability.
