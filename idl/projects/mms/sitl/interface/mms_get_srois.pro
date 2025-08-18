; Wrapper for get_mms_srois
; 


function mms_get_srois, trange = trange, sc_id = sc_id

; One sc_id at a time for now

if ~keyword_set(sc_id) then sc_id = 'mms1'

if ~keyword_set(trange) then begin
  trange = time_string(timerange(/current))
endif

start_time = trange[0]
end_time = trange[1]

sroi_array = get_mms_srois(start_time = start_time, end_time = end_time, sc_id = sc_id)

if ~is_struct(sroi_array) then begin
  return, -1
endif else begin

  starts = sroi_array[*].start_time
  stops = sroi_array[*].end_time
  orbits = sroi_array[*].orbit
  sc_ids = sroi_array[*].sc_id

  outstruct = {starts: starts, $
              stops: stops, $
              orbits: orbits, $
              sc_ids: sc_ids}
             
  return, outstruct
endelse

end