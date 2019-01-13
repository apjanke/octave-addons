octave-addons Developer Notes
=============================



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

* Everything

##