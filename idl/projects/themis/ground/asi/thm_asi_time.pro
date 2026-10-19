;+
;FUNCTION:
;  thm_asi_time
;
;PURPOSE:
;  Convert per-frame metadata from thm_asi_readfile into unix
;  times (double, seconds since 1970-01-01 with no leap seconds) -- the
;  same time convention used by the legacy Berkeley THEMIS ASI CDFs.
;
;INPUT:
;  metadata: array of thm_asi_Pgm_Metadata structures
;
;OUTPUT:
;  double array of unix times (one per frame)
;
;NOTES:
;  The exposure start strings are 'YYYY-MM-DD hh:mm:ss[.ssssss]' UTC,
;  which time_double parses directly.
;-
function thm_asi_time, metadata
  compile_opt idl2
  return, time_double(metadata.exposure_start_string)
end
