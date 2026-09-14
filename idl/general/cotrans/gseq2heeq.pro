;+
;procedure: gseq2heeq
;Purpose: transform GSEQ to Heliocentric Earth Equatorial, or the inverse.
;Use /POSITION for array positions.  Tplot positions are detected from st_type.
;-
pro gseq2heeq, name_in, name_out, HEEQ2GSEQ=heeq2gseq, POSITION=position, $
  ROTATION_ONLY=rotation_only, IGNORE_DLIMITS=ignore_dlimits
  compile_opt idl2
  spd_helio_transform, name_in, name_out, 'heeq', 'gseq', INVERSE=heeq2gseq, $
    POSITION=position, ROTATION_ONLY=rotation_only, IGNORE_DLIMITS=ignore_dlimits
end
