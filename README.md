# Microsoft Word for Windows 1.1a — Native x64 Port

> **Working Windows 11 x64 build**
>
> This fork of the [`jmarshall23/msword`](https://github.com/jmarshall23/msword)
> project restores missing build-generation scripts required to compile the
> native x64 port from a clean checkout.
>
> The `WORD1` target has been successfully compiled, linked, launched, and used
> for basic text input on Windows 11 with Visual Studio 2022.

![Status](https://img.shields.io/badge/Windows%2011-x64-blue)
![Visual Studio](https://img.shields.io/badge/Visual%20Studio-2022-purple)
![Build](https://img.shields.io/badge/WORD1-builds-successfully-brightgreen)

## Fork changes

This fork contains additional compatibility work for running the historical
Microsoft Word 1.1a source on modern 64-bit Windows.

Recent changes include:

- Restored the About dialog version and copyright information.
- Added modern Windows reporting for available memory and disk space.
- Preserved the original Word 1.1a About dialog presentation and legacy
  system-information fields.
- Additional compatibility fixes for the modern x64 build.

## About

This repository contains a native Windows x64 port of the historical source
code for **Microsoft Word for Windows 1.1a**, whose codename was **Opus**.

The upstream project ports the original Word source and resources to modern
64-bit Windows by providing replacements and compatibility layers for the
16-bit assembly, segmented-memory model, Win16 APIs, historical build tools,
and other platform-specific components.

The resulting application is the original Word code running as a native
64-bit Windows executable.

It is **not an emulator**, and it is not a recreation of Word using a modern
editor component.

This repository is a fork of:

https://github.com/jmarshall23/msword

## Why this fork exists

At the time this fork was created, a clean checkout of the upstream repository
could not build the `WORD1` target because its CMake build configuration
referenced two generator scripts that were not included in the repository:

```text
src/cmake/GenerateMenuHelpHeader.cmake
src/cmake/GenerateElxStid.ps1
```

This resulted in build errors such as:

```text
CMake error: Not a file:
src/cmake/GenerateMenuHelpHeader.cmake
```

and:

```text
GenerateElxStid.ps1 ... is not present
```

This fork reconstructs these missing build-generation steps and provides the
compatibility handling needed for the original Word engine to compile and link
with modern MSVC.

The goal is to make the upstream x64 port reproducibly buildable while changing
as little of the original application logic as possible.

---

# What was added

## 1. Menu-help header generation

The original build uses the historical `MKCMD` tool to process the Word command
tables.

As part of that process, `MKCMD` produces:

```text
MENUHELP.TXT
```

containing the menu-help strings used by Word.

For example:

```text
x,      "Menu of Help choices"
x,      "Displays help for current task or command"
x,      "Displays instructions about how to use help"
```

The upstream CMake configuration expected:

```text
src/cmake/GenerateMenuHelpHeader.cmake
```

to convert this output into:

```text
menuhelp.h
```

but the generator script was missing.

This fork reconstructs that step.

The generated x64 header provides the interface expected by the current Word
source:

```c
OPUS_X64_MENU_HELP_STRING(iidstr)
```

allowing code such as:

```c
CchCopySz(OPUS_X64_MENU_HELP_STRING(hpsy->iidstr), sz);
```

to work with a modern C string table.

A bounds check is also used so that an invalid help-string index returns an
empty string rather than reading beyond the generated table.

## 2. EL/STID generation

The CMake build also expects:

```text
src/cmake/GenerateElxStid.ps1
```

to generate:

```text
elxinfo.h
```

This script was likewise absent from the upstream source tree.

The reconstructed PowerShell generator extracts the historical STID data
embedded in:

```text
OpusEtAl/tools/src/mergeelx.c
```

and produces an x64-compatible `elxinfo.h`.

Several assumptions made by the historical Microsoft build environment also
had to be handled during generation.

These include:

### Historical `StringMap` initializer

The original generated data contains an initializer equivalent to:

```c
csconst char rgksp[] = StringMap("SUPO", 0, 1);
```

Modern MSVC cannot use a function call as a compile-time initializer for a
global array.

For the x64 build this is generated as the equivalent constant string:

```c
csconst char rgksp[] = "SUPO";
```

### Historical ELDI generation

The original Word build relied on a historical Dialog Editor/compiler stage
that is not available in the source archive.

The `ELDI` structure also ends in a variable-sized `ELFD` array, which is not
directly usable in the same way by modern MSVC.

The reconstructed generator therefore provides a small compatibility boundary
for the unavailable generated ELDI data while retaining the layout expected by
the existing x64 Word code.

---

# Current status

The following has been **verified on Windows 11 x64**:

- CMake configuration with Visual Studio 2022
- compilation of the native x64 compatibility tools
- execution of the historical `MKCMD` command-table generator
- generation of the original Word command tables
- reconstructed `MENUHELP.TXT` → `menuhelp.h` generation
- reconstructed `mergeelx.c` → `elxinfo.h` generation
- compilation of the original Word/Opus engine
- creation of the Word application library
- linking of `WORD1.exe`
- application startup
- rendering of the Word user interface
- creation/display of a document
- basic text input

The application should still be considered **experimental**.

Microsoft Word 1.1a is a very old codebase being executed in an environment
radically different from the one for which it was originally designed.
Additional functionality may expose assumptions or compatibility issues that
have not yet been tested.

---

# Requirements

The verified build environment is:

- **64-bit Windows 11**
- **Visual Studio 2022 Community**
- Visual Studio workload:
  - **Desktop development with C++**
- Windows 10 or Windows 11 SDK
- **CMake 3.25 or newer**
- PowerShell
- Git

Other configurations may work but have not been verified for this fork.

---

# Installing the prerequisites

## Visual Studio 2022

Install Visual Studio 2022 Community and select:

```text
Desktop development with C++
```

Make sure that a Windows 10 or Windows 11 SDK is included.

Visual Studio 2019 is not sufficient for the supplied CMake presets, which use
the:

```text
Visual Studio 17 2022
```

generator.

## CMake

CMake can for example be installed using `winget`:

```powershell
winget install --id Kitware.CMake -e
```

Close and reopen PowerShell after installation.

Verify:

```powershell
cmake --version
```

---

# Clone this fork

From PowerShell:

```powershell
git clone https://github.com/crapshot1ai/msword.git
Set-Location msword
```

The CMake project itself is located in:

```text
src
```

so enter that directory:

```powershell
Set-Location .\src
```

---

# Build

## Recommended: Release build

The build configuration that has been verified with this fork is:

```powershell
cmake --preset x64-release
cmake --build --preset x64-release --target WORD1
```

The source is historical C code and produces a **large number of compiler
warnings** with modern MSVC.

This is expected.

Warnings alone do not mean that the build failed.

The important result of a successful build is:

```text
bin\WORD1.exe
```

From the `src` directory you can verify this with:

```powershell
Test-Path ..\bin\WORD1.exe
```

A successful build should return:

```text
True
```

---

# Run Word

From the `src` directory:

```powershell
& ..\bin\WORD1.exe
```

Alternatively, launch:

```text
bin\WORD1.exe
```

from Windows Explorer.

---

# Debug build

The repository also provides an x64 Debug preset:

```powershell
cmake --preset x64-debug
cmake --build --preset x64-debug --target WORD1
```

Then run:

```powershell
& ..\bin\WORD1.exe
```

The Release `WORD1` build is the configuration currently verified by this fork.

---

# Clean rebuild

CMake and Visual Studio generate files in:

```text
out
build
bin
```

If you switch between substantially different source revisions or modify the
build-generation scripts, performing a clean rebuild is recommended.

From the repository root:

```powershell
Remove-Item -Recurse -Force .\out -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\bin -ErrorAction SilentlyContinue
```

Then:

```powershell
Set-Location .\src

cmake --preset x64-release
cmake --build --preset x64-release --target WORD1
```

---

# Capturing a build log

Because the original source generates many warnings, saving the complete build
output can make troubleshooting much easier.

From `src`:

```powershell
cmake --build --preset x64-release --target WORD1 2>&1 |
    Tee-Object -FilePath ..\word1-build.log
```

This creates:

```text
word1-build.log
```

in the repository root while still displaying the build output in PowerShell.

For verbose build output:

```powershell
cmake --build --preset x64-release --target WORD1 --verbose 2>&1 |
    Tee-Object -FilePath ..\word1-build-verbose.log
```

---

# Visual Studio solution

After running CMake, the generated Visual Studio solution is located at:

```text
out\MicrosoftWordX64Port.sln
```

It can be opened directly in Visual Studio 2022.

Use:

```text
WORD1
```

as the application target/startup project.

---

# Project layout

| Path | Purpose |
| --- | --- |
| `src/Opus/` | Original Microsoft Word/Opus application source and resources |
| `src/OpusEtAl/` | Original supporting tools, libraries, and build inputs |
| `src/OpusProg/` | Historical program documentation |
| `src/port/original/` | x64 compatibility layer, translated routines, and tests |
| `src/port/tools/` | Native replacements for historical build-time tools |
| `src/cmake/` | Resource/source-generation helpers, including the reconstructed generators |
| `out/` | CMake cache, generated headers, and Visual Studio solution |
| `build/` | Intermediate libraries, tools, tests, PDBs, and diagnostics |
| `bin/` | Final executable and runtime files |

`out`, `build`, and `bin` are generated locally during configuration and
compilation.

---

# How the x64 port works

The original C and resource files remain the authoritative implementation of
Word.

The upstream x64 port provides the platform work necessary to execute that code
on modern 64-bit Windows, including:

- translation/replacement of 16-bit x86 assembly entry points
- x64-safe handling of segmented and double-indirect memory concepts
- adaptation of Win16 startup and messaging behavior
- adaptation to current Win32 APIs
- reconstruction of historical command and resource generation
- native replacements for historical build-time utilities
- compatibility handling for graphics, files, dialogs, resources, and other
  operating-system boundaries

The historical assembly source remains available as a reference but is not
directly compiled into the native AMD64 application.

This fork adds the two missing generator stages required by the current CMake
graph.

---

# Useful targets

| Target | Description |
| --- | --- |
| `WORD1` | Native x64 Microsoft Word executable |
| `opus_original_engine` | Original Word application engine compiled for x64 |
| `opus_x64_runtime` | Native runtime and translated assembly behavior |
| `opus_word1_ui_test` | Automated UI test driver supplied by the upstream project |
| `legacy_sources` | IDE-visible reference collection of the original assembly |

For example:

```powershell
cmake --build --preset x64-release --target WORD1
```

---

# Tests

The upstream repository contains a larger test suite covering parts of the x64
runtime and application.

For example, the upstream documentation uses:

```powershell
ctest --test-dir ..\out -C Release --output-on-failure
```

However, **this fork currently only claims a verified successful build and
runtime launch of the `WORD1` target**.

The complete upstream test suite may contain independent build or linker issues
and should not yet be considered verified by this fork.

---

# Troubleshooting

## `cmake` is not recognized

If PowerShell reports:

```text
cmake : The term 'cmake' is not recognized...
```

install CMake and restart PowerShell.

Verify with:

```powershell
cmake --version
```

## Visual Studio 2022 cannot be found

If CMake reports:

```text
Generator

  Visual Studio 17 2022

could not find any instance of Visual Studio
```

install Visual Studio 2022 with:

```text
Desktop development with C++
```

and a Windows SDK.

You can inspect detected Visual Studio installations with:

```powershell
& "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" `
    -all -products * -property installationPath
```

## Lots of red compiler warnings

This is normal.

The source predates modern C and modern MSVC by decades. The compiler therefore
emits a very large number of warnings.

Look for actual lines containing:

```text
error C...
fatal error...
LNK...
MSB...
```

rather than treating every warning as a failed build.

## Problems after changing branches

Delete the generated build directories and reconfigure:

```powershell
Remove-Item -Recurse -Force .\out -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\bin -ErrorAction SilentlyContinue

Set-Location .\src
cmake --preset x64-release
cmake --build --preset x64-release --target WORD1
```

---

# Upstream project

This fork is based on the work in:

**jmarshall23/msword**

https://github.com/jmarshall23/msword

The native x64 port and the overwhelming majority of the work represented in
this repository come from the upstream project.

This fork specifically aims to:

1. restore the missing CMake/PowerShell generation stages;
2. provide a reproducible build path;
3. document a configuration known to produce a runnable `WORD1.exe`;
4. make it easier for others to experiment with and test the port.

Where possible, improvements should ultimately be suitable for contributing
back upstream.

---

# Historical source and licensing

This repository contains historical Microsoft Word source code and subsequent
porting work.

Before redistributing, modifying, or using the code for purposes beyond
historical, educational, or experimental work, review the licensing and
copyright information contained in the repository and in the upstream project.

The existence of source code in a public repository should not by itself be
interpreted as granting rights beyond those stated by the applicable license
and copyright notices.

---

# Contributing

Bug reports, build fixes, compatibility improvements, and testing of additional
Word functionality are welcome.

Particularly useful areas for further testing include:

- opening and saving documents
- formatting
- menus and menu-help text
- dialogs
- keyboard shortcuts
- printing
- clipboard operations
- fonts
- DOC/DOCX interoperability provided by the port
- stability of the reconstructed EL compatibility boundary
- Debug builds
- automated tests

When reporting a build problem, include:

- Windows version
- Visual Studio version
- CMake version
- build preset
- the first actual compiler/linker error
- preferably a complete build log generated with `Tee-Object`

---

## A small milestone

A clean x64 Release build of the `WORD1` target from this fork has been
successfully launched on Windows 11.

The first test document contained:

> **Hallo Welt**

Which seems like an appropriate way to greet Word 1.1 after more than three
decades.