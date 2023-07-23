;+
; FUNCTION: elf_get_eiscat_positions
;
; PURPOSE:
;     This routine will return the position (latitude and longitude) of 
;     three EISCAT stations (incoherent radar scattering)
;     Stations include: Tromso_UHF, Tromso_VHF, Svalbard
;
; KEYWORDS:
;     None
;     
; OUTPUT:
;    eiscat_pos - a structure containing the station names, latitudes, and longitudes.
;                 ** Structure <28f7a620>, 3 tags, length=72, data length=72, refs=1:
;                 NAME            STRING    Array[3]
;                 LAT             FLOAT     Array[3]
;                 LON             FLOAT     Array[3]
;                 
; EXAMPLE:
;    eiscat_pos = elf_get_eiscat_positions()
;
;-
function elf_get_eiscat_positions

  station_names=['Tromso_UHF', 'Tromso_VHF', 'Svalbard']
  station_lat=[69.6, 69.6, 78.]
  station_lon=[18.9, 18.9, 16.]

  eiscat_pos = {name:station_names, lat:station_lat, lon:station_lon}
  
  return, eiscat_pos
  
end