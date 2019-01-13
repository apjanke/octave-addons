octave-addons Developer Notes
=============================



# Notes on function areas

## time

### References

See `man tzfile` or [here](http://man7.org/linux/man-pages/man5/tzfile.5.html) for the time zone file format definition.

### TODO

* `datetime`
  * `Format` support
  * Time zone conversion
  * Leap second conversion
  * Date component (Year/Month/Day/...) property access
  * Additional `ConvertFrom` types
* Fix parsing bug with that trailing data/time zone in the zoneinfo files
* `calDuration` and its associated functions
* Plotting support
  * Maybe with just shims and conversion to datenums
* `duration`
  * `InputFmt` support
  * `Format` support

## table

### TODO

* Everything

##