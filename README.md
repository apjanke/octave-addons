octave-addons
===============

Experimental add-on functionality for GNU Octave

This repo contains code I'm working on for GNU Octave, with the hopes of some
of it making it into upstream GNU Octave.

All the code in here is experimental. Do not use it in any production code!

## Installation and usage

Installation:

* Clone the repo
  * `git clone https://github.com/apjanke/octave`
* Build all the octfiles
  * Running `oct_addons_build_all_octfiles` will do this
    * (As soon as I have implemented it, that is.)

Usage:
* Run the `load_octave_addons` function from `boostrap/` to set up your path with this library.

## Naming conventions

Functions starting with `oct_addons_` and those in the `+oct_addons` namespace
are for the internal use of the octave-addons repo and are not expected to
make it into user-visible code or APIs.

## Dependencies

The planar-gen code used to generate class definitions is from
[Janklab](https://github.com/apjanke/janklab).

## Author

Octave-addons is created by [Andrew Janke](https://apjanke.net).
