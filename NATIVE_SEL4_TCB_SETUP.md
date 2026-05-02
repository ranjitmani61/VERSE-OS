# Native seL4 TCB Restart Setup

Status: Ubuntu 24.04 Docker manifest sync completed on 2026-05-02. The checked revision exposes internal/generated TCB handling, but no built-in CAmkES `seL4TCB` connector was found.

## Current Blocker

The recovered repository does not contain a native seL4 checkout. There is no local `kernel/`, `projects/`, or CAmkES build tree at the repository root.

The host Python is:

```text
Python 3.14.4
```

Earlier native CAmkES attempts failed because the parser dependency stack was not compatible with the host Python environment. The current Docker image builds the existing CAmkES apps reliably, but connector inspection shows kernel TCB code exists while no CAmkES `seL4TCB` connector is available in the image.

## Ubuntu 24.04 Docker Attempt - 2026-05-02

Command path used:

```bash
docker run --rm -v /tmp/verse_sel4_tcb_attempt:/work ubuntu:24.04 bash
apt-get update
apt-get install -y --no-install-recommends ca-certificates git curl python3 python3-venv python3-pip repo grep
repo init -u https://github.com/seL4/camkes-manifest.git
repo sync -j2 --fail-fast
```

Result: manifest checkout and `repo sync` completed successfully inside Ubuntu 24.04 with Python 3.12.

Synced repository heads:

```text
camkes.git 3de1c46
camkes-tool.git a9262c2
capdl.git 33aec91
seL4.git daa0dfb14
seL4_tools.git 03454f9
sel4runtime 86489cf
```

Connector search result: no `seL4TCB` connector definition was found in `projects/camkes` or `projects/camkes-tool`. The built-in connector list includes the normal endpoint, notification, dataport, hardware, DMA, DTB, and GDB connectors. TCB references do exist in generated CAmkES templates and runtime support, including `seL4_TCB_Suspend(camkes_get_tls()->tcb_cap)` for self pause/exit and generated component TCB allocation, but that does not hand one component authority over another component's TCB.

Conclusion: Priority 3 cannot be completed by simply wiring a stock `seL4TCB` CAmkES connector at this revision. Real ProcMan-enforced restart needs a custom capDL/root-task authority handoff.

## Ubuntu 24.10 Docker Attempt - 2026-05-02

Ubuntu 24.10 (`oracular`) now needs `old-releases.ubuntu.com` inside the container. A plain `apt-get update` against the default `archive.ubuntu.com` and `security.ubuntu.com` sources failed with:

```text
E: The repository 'http://archive.ubuntu.com/ubuntu oracular Release' does not have a Release file.
E: The repository 'http://security.ubuntu.com/ubuntu oracular-security Release' does not have a Release file.
```

After replacing the container apt sources with `old-releases.ubuntu.com`, the container reported:

```text
Python 3.12.7
```

The first CMake attempt failed because `python3-yaml` was not installed:

```text
ModuleNotFoundError: No module named 'yaml'
```

After adding `python3-yaml`, CAmkES parsing failed because the CAmkES parser stack was not installed:

```text
ModuleNotFoundError: No module named 'plyplus'
```

Installing the synced CAmkES dependency metapackage fixed the parser dependency stack:

```bash
pip3 install --break-system-packages ./projects/camkes-tool/tools/python-deps
```

With those Python dependencies installed, CMake configuration succeeded and Ninja started compiling. The build then stopped during libsel4 syscall header generation because the container was missing `xmllint`:

```text
/work/kernel/tools/xmllint.sh: line 14: xmllint: command not found
ninja: build stopped: subcommand failed.
```

Conclusion: Ubuntu 24.10 is not blocked by the host Python 3.14 issue when used in Docker. Python 3.12.7 reaches CAmkES generation after installing `camkes-tool/tools/python-deps`. The next 24.10 retry should add `libxml2-utils` for `xmllint`; this run did not yet produce a complete native image.

## Native Ubuntu 26 Quick Check - 2026-05-02

The native host is:

```text
Ubuntu 26.04 LTS
Python 3.14.4
```

No native seL4/CAmkES checkout was present under the repository root, so no full host build was attempted. A narrow Python compatibility check was run in an isolated `/tmp` virtual environment instead:

```bash
python3 -m venv /tmp/verse_py314_camkes_check
/tmp/verse_py314_camkes_check/bin/python -m pip install camkes-deps==0.7.4
```

Result: the CAmkES dependency metapackage installed under Python 3.14.4, and the key modules imported successfully: `yaml`, `plyplus`, `jinja2`, `ordered_set`, `elftools`, `pyfdt`, `hypothesis`, and `sortedcontainers`.

A shallow `camkes-tool` source import check at the previously inspected revision also passed:

```text
CAMKES_IMPORT_OK
```

It emitted only this warning:

```text
SyntaxWarning: "\W" is an invalid escape sequence
```

Native host tools present: `git`, `repo`, `cmake`, `ninja`, `gcc`, `g++`, `xmllint`, and `python3-yaml`. `qemu-system-x86` was not on PATH.

Conclusion: Python 3.14 is no longer proven-bad at the dependency/import level. It may be viable for a native build, but it is still less reproducible than the Docker path because there is no native checkout yet and QEMU is missing. Do not switch the main TCB path back to host-native until a full manifest sync and build are intentionally attempted.

## Custom capDL Extension Needed

If the selected CAmkES revision remains connector-limited, the custom path must:

1. Name the managed worker TCB object in the generated capDL spec.
2. Mint or copy a narrowly scoped worker TCB capability into ProcMan's CSpace.
3. Expose enough worker resource authority for teardown: worker CNode slots, VSpace/root page table, IPC buffer mapping, scheduling context, and fault endpoint configuration.
4. Prevent broad authority escalation: ProcMan must receive only the specific worker-management caps, not arbitrary mint/retype rights.
5. Add generated symbol names or bootstrap metadata so ProcMan can locate the worker TCB cap deterministically at runtime.
6. Extend the capability audit rules to flag unexpected ProcMan authority over unrelated components.
7. Prove the runtime path with logs showing `seL4_TCB_Suspend(worker_tcb)`, resource teardown/rebuild, fresh register setup, and successful worker resume.

## What Is Required

Real restart requires ProcMan or Watchdog to hold authority over the managed worker thread:

1. Receive or mint a `seL4_TCB` capability for the worker.
2. Configure the worker fault endpoint.
3. On crash or timeout, call `seL4_TCB_Suspend`.
4. Revoke or rebuild the worker CSpace/VSpace as required.
5. Create or reinitialize a fresh worker TCB.
6. Set registers, IPC buffer, scheduling context, and entry point.
7. Resume the fresh worker and re-arm Watchdog.

The current prototype does not have those capabilities. It demonstrates cooperative restart through `kill_flag` and `restart_flag` dataports.

## Recommended Build Path

Use an older, controlled build environment instead of the host Python 3.14 stack:

```bash
docker run --rm -it -v "$HOME/verse_os:/host" ubuntu:24.04 bash
```

Inside that container:

```bash
apt-get update
apt-get install -y \
    build-essential cmake ninja-build git curl ca-certificates \
    python3.12 python3.12-venv python3-pip python3-six python3-yaml \
    libxml2-utils \
    qemu-system-x86 repo

mkdir -p /work/sel4
cd /work/sel4
repo init -u https://github.com/seL4/camkes-manifest.git
repo sync -j"$(nproc)"
pip3 install --break-system-packages ./projects/camkes-tool/tools/python-deps
```

Then copy VERSE OS apps into the checked-out CAmkES app tree and test whether the selected CAmkES revision supports direct TCB capability connectors. If it does not, the next step is a custom root-task or capDL extension that hands ProcMan the worker TCB capability explicitly.

## Completion Criteria

Priority 3 is complete only when a runtime log proves an enforced path:

```text
Watchdog: fault or heartbeat timeout
ProcMan: seL4_TCB_Suspend(worker_tcb) OK
ProcMan: revoked/rebuilt worker resources
ProcMan: started fresh worker TCB
TestWorker: started fresh instance
```

Until then, the honest claim is cooperative self-healing, not real TCB-based respawn.
