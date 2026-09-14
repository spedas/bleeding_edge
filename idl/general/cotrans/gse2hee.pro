;+
;procedure: gse2hee
;Purpose: transform GSE to Heliocentric Earth Ecliptic, or the inverse.
;Use /POSITION for array positions.  Tplot positions are detected from st_type.
;-
pro gse2hee, name_in, name_out, HEE2GSE=hee2gse, POSITION=position, $
  ROTATION_ONLY=rotation_only, IGNORE_DLIMITS=ignore_dlimits
  compile_opt idl2
  spd_helio_transform, name_in, name_out, 'hee', 'gse', INVERSE=hee2gse, $
    POSITION=position, ROTATION_ONLY=rotation_only, IGNORE_DLIMITS=ignore_dlimits
end
