# RWX Kernel LOAD Segment Evidence

Date: 2026-05-02

## Verdict

The current x86_64 simulation build still emits the RWX kernel LOAD segment
warning. This was inspected and documented, not fixed.

The warning is for `kernel/kernel.elf`. In the same evidence build, the
`capdl-loader-image-x86_64-pc99` executable did not contain an RWX `PT_LOAD`
segment. This document does not prove W^X for every user-space mapping.

This is not an application-level Verse OS issue. A real fix would require
changing the seL4 pc99 kernel linker layout and validating matching x86_64
kernel mappings. No such kernel change is committed here.

The system must not be described as hardened or kernel-W^X clean while this
warning remains.

## Evidence Bundle

Fresh evidence directory:

```text
out/rwx_issue5_20260502_final/
```

Files saved from the exact build that was booted:

```text
build.log
boot.log
CMakeCache.txt
config_relevant_lines.txt
kernel.elf
kernel-x86_64-pc99
capdl-loader-image-x86_64-pc99
kernel_readelf_segments.txt
kernel_readelf_sections.txt
capdl_loader_readelf_segments.txt
linker.lds_pp
linker_relevant_lines.txt
seL4_pc99_linker.lds
seL4_linker_relevant_lines.txt
seL4_x86_64_vspace.c
vspace_relevant_lines.txt
```

## Build Evidence

Build command shape:

```sh
../init-build.sh -DPLATFORM=x86_64 -DSIMULATION=TRUE -DCAMKES_APP=verse_unified -DVERSE_TCB_ENFORCED=ON
ninja
python3 /host/tools/inject_tcb_handoff.py verse_unified.cdl verse_unified_tcb_handoff.cdl
ninja images/capdl-loader-image-x86_64-pc99
```

Build log:

```text
out/rwx_issue5_20260502_final/build.log
```

Observed markers:

```text
402:/usr/bin/ld: warning: kernel/kernel.elf has a LOAD segment with RWX permissions
412:RWX_ISSUE5_FINAL_BUILD_OK
```

Relevant generated config:

```text
655:KernelHugePage:BOOL=ON
1115:SIMULATION:UNINITIALIZED=TRUE
1162:VERSE_TCB_ENFORCED:BOOL=ON
```

## Kernel ELF Program Headers

Command output saved in:

```text
out/rwx_issue5_20260502_final/kernel_readelf_segments.txt
```

Observed `kernel.elf` program headers:

```text
LOAD           0x000000 0x0000000000100000 0x0000000000100000 0x00034f 0x008000 RW  0x1000
LOAD           0x00034f 0xffffffff8010834f 0x000000000010834f 0x0084ab 0x609651 RWE 0x40
LOAD           0x0087fa 0xffffffff808007fa 0x00000000008007fa 0x028e5c 0x212006 RWE 0x2000
```

Observed section mapping:

```text
00     .phys .phys.bss
01     .boot .boot.bss
02     .text .rodata .skim_bss .bss ._idle_thread
```

The warning is real for this kernel ELF: two kernel `PT_LOAD` segments are
marked `RWE`.

## Linker Script Source

Generated linker output:

```text
out/rwx_issue5_20260502_final/linker.lds_pp
out/rwx_issue5_20260502_final/linker_relevant_lines.txt
```

seL4 source copied from the Docker build tree:

```text
out/rwx_issue5_20260502_final/seL4_pc99_linker.lds
out/rwx_issue5_20260502_final/seL4_linker_relevant_lines.txt
```

Relevant linker structure:

```text
30:PHDRS {
31:    phys PT_LOAD FILEHDR PHDRS ;
32:    boot PT_LOAD ;
33:    virt PT_LOAD ;
34:}
```

The `boot` program header receives both boot code/data and boot BSS:

```text
62:    .boot . : AT(ADDR(.boot) - KERNEL_OFFSET)
64:        *(.boot.text)
65:        *(.boot.data)
66:    } :boot
68:    .boot.bss . (NOLOAD) : AT(ADDR(.boot.bss) - KERNEL_OFFSET)
70:        *(.boot.bss)
71:    } :boot
```

The `virt` program header receives executable text plus writable data/BSS
classes:

```text
91:    .text . : AT(ADDR(.text) - KERNEL_OFFSET)
93:        *(.text)
94:    } :virt
96:    .rodata . : AT(ADDR(.rodata) - KERNEL_OFFSET)
98:        *(.rodata)
99:        *(.rodata.*)
100:    } :virt
126:    .data . : AT(ADDR(.data) - KERNEL_OFFSET)
128:        *(.data)
129:    } :virt
131:    .bss . (NOLOAD) : AT(ADDR(.bss) - KERNEL_OFFSET)
133:        *(.bss)
135:    } :virt
139:    ._idle_thread . (NOLOAD): AT(ADDR(._idle_thread) - KERNEL_OFFSET)
142:        *(._idle_thread)
144:    } :virt
```

Because executable and writable sections are assigned to the same `PT_LOAD`
program headers, GNU ld emits `RWE` permissions for those headers.

## Runtime Mapping Inspection

The evidence build has:

```text
KernelHugePage:BOOL=ON
```

The copied seL4 x86_64 vspace source shows the huge-page mapping for
`KERNEL_ELF_BASE` is created with execute disable clear and writable set:

```text
76:    x64KSKernelPDPT[GET_PDPT_INDEX(KERNEL_ELF_BASE)] = pdpte_pdpte_1g_new(
77:                                                           0, /* xd */
78:                                                           PADDR_BASE,
86:                                                           1, /* read_write */
87:                                                           1  /* present */
88:                                                       );
```

Therefore, kernel runtime W^X is not proven for this build. The warning is not
just hidden metadata in the app tree.

This document does not re-prove seL4 capability isolation or user/supervisor
separation. It only records that the RWX warning is kernel-image specific and
that normal active-TCB failover behavior still boots with the warning present.

## capDL Loader Program Headers

Command output saved in:

```text
out/rwx_issue5_20260502_final/capdl_loader_readelf_segments.txt
```

Observed `capdl-loader-image-x86_64-pc99` `PT_LOAD` headers:

```text
LOAD           0x000000 0x0000000000400000 0x0000000000400000 0x0001ec 0x0001ec R   0x1000
LOAD           0x001000 0x0000000000401000 0x0000000000401000 0x01f91f 0x01f91f R E 0x1000
LOAD           0x021000 0x0000000000421000 0x0000000000421000 0x78b098 0x78b098 RW  0x1000
LOAD           0x000000 0x0000000000bb0000 0x0000000000bb0000 0x000000 0x0ab180 RW  0x10000
```

No RWX `PT_LOAD` segment was observed in the capDL loader executable.

## Normal Recovery Boot Evidence

Boot log:

```text
out/rwx_issue5_20260502_final/boot.log
```

Positive markers:

```text
82:VERSE_RECOVERY_PASS_1
83:WDOG: heartbeat resumed, re-armed and monitoring
147:SIMULATE_EXIT:124
```

Rejected-marker grep:

```sh
grep -nE "Caught cap fault|vm fault|FAULT HANDLER|fault|Error|ProcMan: restart attempt 2/3|ProcMan: restart attempt 3/3|ProcMan: QUARANTINE" out/rwx_issue5_20260502_final/boot.log
```

Observed result: no matches.

## Decision

No linker-script or kernel-vspace change is made in this issue.

Reason: the smallest honest action is documentation. Removing the warning
correctly would require a seL4 kernel hardening change, not a Verse OS
application change, and the current active-TCB failover claim does not depend on
claiming kernel W^X.

The current valid claim remains limited to bounded active-TCB failover with
watchdog-confirmed worker recovery.

## Not Proven

- Kernel W^X is not proven.
- A hardened build is not proven.
- The RWX kernel LOAD segment warning is not fixed.
- Clean QEMU shutdown is not proven; this run ended with `SIMULATE_EXIT:124`.
- This document does not audit every user-space component mapping.
