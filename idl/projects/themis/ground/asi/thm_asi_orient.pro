;+
;FUNCTION:
;  thm_asi_orient
;
;PURPOSE:
;  Apply the single authoritative orientation transform that maps a raw
;  archive image array (as returned by thm_asi_readfile,
;  in native PGM orientation) onto the orientation used by the legacy
;  Berkeley THEMIS ASI CDF images (thg_asf_<site> / thg_ast_<site>).
;
;  The transform is rotate(img, 2), i.e. a 180-degree rotation. It was
;  pinned empirically (2026-08-07) by comparing all 20 frames of
;  20080210_0713_fykn_themis14_full.pgm.gz against the same frames in
;  thg_l1_asf_fykn_2008021007_v01.cdf: rotate(...,2) reproduces the CDF
;  pixel values bit-identically; all other rotate() directions match
;  zero frames.
;
;  The same transform must be applied to any per-pixel calibration arrays
;  derived from skymaps (elevation, azimuth, corner grids) so
;  that they stay aligned with the images. For the 257x257 corner grids
;  the 180-degree rotation maps corner (i,j) -> (256-i,256-j), which
;  rotate(...,2) also handles correctly.
;
;INPUT:
;  img: 2-D image or calibration array (any type)
;
;OUTPUT:
;  the array rotated 180 degrees
;-
function thm_asi_orient, img
  compile_opt idl2
  return, rotate(img, 2)
end
