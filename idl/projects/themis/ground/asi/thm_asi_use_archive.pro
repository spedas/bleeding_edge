;+
;FUNCTION:
;  thm_asi_use_archive
;
;PURPOSE:
;  Single place that decides which loading path the THEMIS ASI / REGO
;  loaders (thm_load_asi, thm_load_rego, thm_load_ask, thm_load_asi_cal)
;  and the mosaic routines take for a given pair of keywords:
;
;    /CDF_LEGACY   -> Berkeley CDF path (always wins when set)
;    /UCALGARY_PGM  -> data archive path (data.phys.ucalgary.ca)
;    neither       -> the DEFAULT, currently the Berkeley CDF path
;
;  To make the data archive the default instead, change only the last
;  line of this function to
;      return, 1b
;  Every caller passes both keywords through, so no other file needs to
;  change for the flip, and /cdf_legacy keeps working as the way back.
;
;INPUT KEYWORDS:
;  ucalgary_pgm: request the data archive path
;  cdf_legacy:  request the Berkeley CDF path
;
;OUTPUT:
;  1b if the data archive path should be used, 0b for the Berkeley CDF path
;-
function thm_asi_use_archive, ucalgary_pgm = ucalgary_pgm, cdf_legacy = cdf_legacy

  compile_opt idl2, hidden

  if keyword_set(cdf_legacy) then return, 0b
  if keyword_set(ucalgary_pgm) then return, 1b
  ; ---- default when neither keyword is given
  return, 0b
end
