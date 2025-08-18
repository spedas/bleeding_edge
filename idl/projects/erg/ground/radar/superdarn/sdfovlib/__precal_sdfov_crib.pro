;pro __precal_sdfov_crib
; This crib sheet needs the ERG-SC plug-in.

thm_init
timespan, '2012-12-01'
sd_init
sd_time, 1400  ; draw FOVs and coast lines for 2012-12-01/12:00:00

window, 0, xsize=800, ysize=480
erase

;;Northen hemis.
sd_map_set, /geo, /stereo, center_glat=89.99, center_glon=0., $
  position=[0.02, 0.1, 0.49, 0.9] 

loadct2, 0 ;B-W linear color table
overlay_map_precal_sdfov, /nh,/fil, color=200
;overlay_map_precal_sdfov, /nh, color=254, linethi=1.2
overlay_map_precal_sdfov, color=254, linethick=1.2, $
  site=strsplit('bks cve cvw fhe fhw hok wal', /ext )
overlay_map_coast, col=150
map_grid, latdel=10., londel=15.

;;Southen hemis.
sd_map_set, /geo, /stereo, center_glat=-89.99, center_glon=180., $
  position=[0.51, 0.1, 0.98, 0.9] 

loadct2, 0 ;B-W linear color table
overlay_map_precal_sdfov, /sh,/fil, color=200
;overlay_map_precal_sdfov, /sh, color=254, linethi=1.2
overlay_map_precal_sdfov, color=254, linethick=1.2, $
  /sh
overlay_map_coast, col=150
map_grid, latdel=10., londel=15.


loadct2, 43  ;Restore the default TDAS color table "FAST-Special"









end
