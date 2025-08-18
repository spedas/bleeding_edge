;+
; PROCEDURE:
;         elf_convert_state_gei2sm
;
; PURPOSE:
;         Convert previously loaded state data from gei coordinates to SM. This is a 
;         utility routine. This coordinate conversion occurs frequently in ELFIN code
;
; KEYWORDS:
;         probe: spacecraft probe name 'a' or 'b'
;-
pro elf_convert_state_gei2sm, probe=probe

  ; check that data was loaded
  get_data,'el'+probe+'_pos_gei',data=dats, dlimits=dl, limits=l  ; position in GEI
  if size(dats, /type) EQ 8 then begin
    ; Coordinate transform from gei to sm
    cotrans, 'el'+probe+'_pos_gei', 'el'+probe+'_pos_gse', /gei2gse
    cotrans, 'el'+probe+'_pos_gei', 'el'+probe+'_pos_geo', /gei2geo
    cotrans, 'el'+probe+'_pos_gse', 'el'+probe+'_pos_gsm', /gse2gsm
    cotrans, 'el'+probe+'_pos_gsm', 'el'+probe+'_pos_sm', /gsm2sm
  endif else begin
    print, 'Error: No state pos gei data is available'
    return
  endelse
  
end