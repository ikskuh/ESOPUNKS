# ESOPUNKS

Implements a [ESOPUNKS](https://esolangs.org/wiki/ESOPUNK) runtime in Zig.

## Concepts

### Stepped execution

### `REPL`

Replicating an EXA is done via [fork](https://man7.org/linux/man-pages/man2/fork.2.html) on Linux, replicating the process for each EXA.

### `GRAB`, `WIPE`, `MAKE`, `FILE`

EXAs can read any UTF-8 text file with a name that only contains numbers as a name or have their name stored in a *keyword*. To open a file named `"TEST.TXT"`, an auxilliary file is required:

**code.exa:**
```exa
GRAB 100
COPY F X
DROP 100

GRAB X
…
```

**100:**
```
TEST.TXT
```

When reading files, an EXA will separate file entries by any UTF-8 character that is less or equal to 0x20.

When writing files, the EXA will separate file entries by a SPACE character (0x20).

### `LINK` and `HOST`

Linking to different machines in this implementation of ESOPUNKS will not be implemented, as moving a running EXA to another machine would require services to run on other machines. This might be implemented in a future version though.

### Implementing `MODE`, `M` and `TEST MRD`

`LOCAL` communication between different EXAs on the same machine is done via a [message queue](https://man7.org/linux/man-pages/man2/mq_open.2.html) called "EXA" on Linux.

`GLOBAL` communication between different EXAs across several machines is done via [udp multicast](https://en.wikipedia.org/wiki/Multicast), using the same binary format as `LOCAL` communications.

Each message contains if the data transferred is a *keyword* (utf-8 string) or a *number* (i32).