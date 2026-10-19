;+
;FUNCTION:
;  srscan_trex_rgb_sites
;
;PURPOSE:
;  Return the table of TREx RGB all-sky imager sites. This is the ONE
;  authoritative site list for the srs_canada TREx RGB routines: the
;  loaders, mosaic driver, and map defaults all resolve sites against this
;  function, so site changes are one-line edits here.
;
;OUTPUT:
;  Array of structures {uid, name, glat, glon} with geographic latitude
;  (deg) and east longitude (deg, -180..180).
;
;NOTES:
;  Coordinates are the nominal site locations; the per-site skymap files
;  (srscan_trex_rgb_skymap) carry the precise calibrated values and are
;  what the mosaic geometry actually uses.
;
;EXAMPLE:
;  sites = srscan_trex_rgb_sites()
;  print, sites.uid
;-
function srscan_trex_rgb_sites

  compile_opt idl2

  return, [ $
    {uid: 'atha', name: 'Athabasca, AB',      glat: 54.60d, glon: -113.64d}, $
    {uid: 'fsmi', name: 'Fort Smith, NT',     glat: 60.03d, glon: -111.93d}, $
    {uid: 'gill', name: 'Gillam, MB',         glat: 56.38d, glon: -94.64d}, $
    {uid: 'luck', name: 'Lucky Lake, SK',     glat: 51.15d, glon: -107.26d}, $
    {uid: 'pina', name: 'Pinawa, MB',         glat: 50.26d, glon: -95.87d}, $
    {uid: 'rabb', name: 'Rabbit Lake, SK',    glat: 58.23d, glon: -103.68d}, $
    {uid: 'yknf', name: 'Yellowknife, NT',    glat: 62.52d, glon: -114.31d} $
  ]
end
