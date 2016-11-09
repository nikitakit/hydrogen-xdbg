# Hydrogen + xdbg

[xdbg](https://github.com/nikitakit/xdbg) is a cross between a Jupyter kernel and a debugger. It allows moving the Jupyter kernel execution environment to any scope within the program, including inside functions and other modules.

This [Hydrogen](https://github.com/nteract/hydrogen) plugin tracks which file you have open in atom, and executes commands in the module corresponding to that file. This allows live-coding that spans multiple files.

The plugin is currently highly experimental. It interacts with Hydrogen internals instead of just the plugin API, meaning that it needs to be upgraded in sync with new versions of Hydrogen.

## Usage

* Install `hydrogen` and `hydrogen-xdbg` into Atom. Also install `xdbg` into your python environment.
* Connect hydrogen to a remote Python kernel on a notebook server or gateway. (Local ZMQ Kernels are not supported).
* Import some modules from local files.
* As you switch between files in hydrogen, watch the status bar keep track of which module code will be run in.
