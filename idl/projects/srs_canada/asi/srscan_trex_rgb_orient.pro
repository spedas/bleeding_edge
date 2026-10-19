;+
;FUNCTION:
;  srscan_trex_rgb_orient
;
;PURPOSE:
;  The one authoritative orientation transform for TREx RGB image and
;  skymap arrays. Apply it to EVERYTHING with a pixel-y dimension (raw
;  frames, skymap lat/lon/elevation grids, corner grids) and the arrays
;  line up with each other and render north-up/east-right with tv,/true
;  (matching the archive quicklook orientation).
;
;  As stored in the archive files, x increases eastward and y increases
;  SOUTHWARD; the fix is a flip of the y dimension:
;    [553,480]  or [554,481]   2-D grids   -> reverse(a, 2)
;    [3,553,480]               one frame   -> reverse(a, 3)
;    [n,3,553,480]             frame cube  -> reverse(a, 4)
;  i.e. always the LAST dimension, which is what this function does.
;
;  NOTE: this is a pure y-flip (reverse), NOT the 180-degree rotation
;  (rotate(img,2)) that THEMIS ASI and REGO need -- the TREx RGB x axis is
;  already east-positive. Pinned empirically against the archived hourly
;  keograms and mosaic grids.
;
;INPUT:
;  img: 2-D, 3-D, or 4-D array in archive orientation (any numeric type)
;
;OUTPUT:
;  The array with the y (last) dimension reversed.
;-
function srscan_trex_rgb_orient, img

  compile_opt idl2

  return, reverse(img, size(img, /n_dimensions))
end
