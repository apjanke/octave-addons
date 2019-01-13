octave-addons Developer Notes
=============================

# Overall TODO

* Convert to GNU code style
* Report the Octave crash that happens when I'm in a file stopped in the debugger, make changes to that file, and save it with Cmd-S while it's still stopped in the debugger.

# Notes on function areas

## time

### References

See `man tzfile` or [here](http://man7.org/linux/man-pages/man5/tzfile.5.html) for the time zone file format definition.

### TODO

* `datetime`
  * `Format` support
    * Needs LDML format support, not datestr() format placeholders
  * week() function
  * isdst/isweekend
  * between, caldiff, dateshift, isbetween
  * colon operator
  * linspace()
  * Time zone conversion
  * Leap second conversion
  * Additional `ConvertFrom` types
  * Remove proxykeys
  * Trailing name/val option support in constructor
  * SystemTimeZone non-Java implementation
* `TzDb`
  * timezones top-level function
    * Requires `table`
  * Fix defined time zone listing: the list in zone.tab is not complete
* Fix parsing bug with that trailing data/time zone in the zoneinfo files
* `calDuration` and its associated functions
* Plotting support
  * Maybe with just shims and conversion to datenums
* `duration`
  * `InputFmt` support
  * `Format` support
  * Remove proxykeys
  * split()
  * linspace()
  * colon operator?


## table

### TODO

* Proxykeys
* Relational operations
  * merge, setdiff, union, intersect
* unique
* Get subsasgn assignment to work
 * It's currently erroring: `error: invalid dot name structure assignment because the structure array is empty.  Specify a subscript on the structure array to resolve.`

##