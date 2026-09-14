;+
;procedure: gei2hae
;Purpose: transform GEI to Heliocentric Aries Ecliptic, or the inverse.
;Use /POSITION for array positions.  Tplot positions are detected from st_type.
;-
pro gei2hae, name_in, name_out, HAE2GEI=hae2gei, POSITION=position, $
  ROTATION_ONLY=rotation_only, IGNORE_DLIMITS=ignore_dlimits
  compile_opt idl2
  spd_helio_transform, name_in, name_out, 'hae', 'gei', INVERSE=hae2gei, $
    POSITION=position, ROTATION_ONLY=rotation_only, IGNORE_DLIMITS=ignore_dlimits
end
