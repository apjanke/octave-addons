octave-addons
===============

Experimental add-on functionality for GNU Octave

This repo contains code I'm working on for GNU Octave, with the hopes of some
of it making it into upstream GNU Octave.

All the code in here is experimental. Do not use it in any production code!

## Installation and usage

* Clone the repo
  * `git clone https://github.com/apjanke/octave`
* Add the `Mcode/` directory to your Octave path
* Build all the octfiles
  * Running `oct_addons_build_all_octfiles` will do this

## Naming conventions

Functions starting with `oct_addons_` are for the internal use of the octave-addons
repo and are not expected to make it into user-visible code.

## Dependencies

The planar-gen code used to generate class definitions is from
[Janklab](https://github.com/apjanke/janklab).

## Author

Octave-addons is created by [Andrew Janke](https://apjanke.net).
