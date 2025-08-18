;+
; FUNCTION: elf_get_vlf_positions
;
; PURPOSE:
;     This routine will return the position (geo latitude/longitude and mag latitude/longitude)
;     of seven VLF stations (incoherent radar scattering)
;     stations include: 'IST', 'OUJ', 'MAM', 'GAK', 'ATH', 'KAP', 'KAN'
;
; KEYWORDS:
;     None
;
; OUTPUT:
;    vlf_pos - a structure containing the station names, geo and magh lat/lon.
;              ** Structure <3d936c30>, 5 tags, length=224, data length=224, refs=1:
;              NAME            STRING    Array[7]
;              GLAT            FLOAT     Array[7]
;              GLON            FLOAT     Array[7]
;              MLAT            FLOAT     Array[7]
;              MLON            FLOAT     Array[7]
;
; EXAMPLE:
;    vlf_pos = elf_get_vlf_positions()
;
;-
function elf_get_vlf_positions

  station_names=['IST', 'OUJ', 'MAM', 'GAK', 'ATH', 'KAP', 'KAN']
  station_glat=[70.03, 64.51, 63.06, 62.39, 54.60, 49.39, 67.72]
  station_glon=[88.01, 27.73, 129.56, 214.78, 246.36, 277.81, 26.27]
  station_mlat=[60.6, 61.3, 58.0, 63.6, 61.2, 58.7, 64.6]
  station_mlon=[166.6, 117.4, 202.0, 268.51, 307.2, 347.6, 106.5]

  vlf_pos = {name:station_names, glat:station_glat, glon:station_glon, mlat:station_mlat, mlon:station_mlon}

  return, vlf_pos

end