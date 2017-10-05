;+
; Procedure: goes_load_pos
; 
; Purpose:
;   Loads ephemeris data for GOES spacecraft using SSCWeb
;         
; Keywords: 
;             trange:       Standard time range of interest
;             probe:        Number of the GOES spacecraft, i.e., probes=15 or probes='15'
;             coord_sys:    Coordinate system for the requested ephemeris data; defaults to GEI (geij2000)
;                           Valid coordinate systems are: geo, gm, gse, gsm, sm, geitod, geij2000
;
; Example:
;   To load the GOES-10 position data for the month of January, 2008, in GSM coordinates:
;   
;     goes_pos = goes_load_pos(trange=['2008-01-01', '2008-01-31'], probe=10, coord_sys='gsm')
;     help, /st, goes_pos
;   
;   goes_pos is set to a structure containing the position [x, y, z], time and coordinate system. 
; 
; Notes:
;     Requires the SSC web services IDL library
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-02-28 14:10:44 -0800 (Fri, 28 Feb 2014) $
; $LastChangedRevision: 14467 $
; $URL $
;-
function goes_load_pos, trange = trange, probe = probe, coord_sys = coord_sys
    compile_opt idl2
    if undefined(coord_sys) then coord_sys = 'geij2000'
    
    if (keyword_set(trange) && n_elements(trange) eq 2) $
      then tr = timerange(trange) $
      else tr = timerange()
      
    ; sc, in this case, should have the form goes# where # is the spacecraft #
    sc = strcompress('goes'+string(probe), /rem)
    
    catch, errstats
    if errstats ne 0 then begin
        dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
        catch, /cancel
        return, 0
    endif
    
    ssc_goes_locations = spdfgetlocations(sc, trange, coordinateSystem=coord_sys)

    if (size(ssc_goes_locations, /type) ne 11 || obj_valid(ssc_goes_locations) eq 0) then begin
        dprint, dlevel = 0, 'Error loading GOES position data'
        return, 0
    endif
    
    ; get time values from the loaded data
    goes_jultime_values = ssc_goes_locations->gettime()
    goes_time_values = dblarr(n_elements(goes_jultime_values))
    if goes_jultime_values[0] lt -1095 || goes_jultime_values[n_elements(goes_jultime_values)-1] gt 1827933925 then begin
        dprint, dlevel=0, 'Error, invalid Julian times from spdfgetlocations'
        return, 0
    endif

    ; convert from Julian time
    for jultime_idx = 0, n_elements(goes_jultime_values)-1 do begin
        caldat, goes_jultime_values[jultime_idx], month, day, year, hour, minute, second
        ; need to have the form yy-mm-dd/hh:mm:ss
        timestr_concat = strcompress(string(year) + '-' + string(month) + '-' + $
          string(day) + '/' + string(hour) + ':' + string(minute) + ':' + string(second), /rem)
        goes_time_values[jultime_idx] = time_double(timestr_concat)
    endfor
    
    ; store the position vector in a single variable
    goes_pos_values = dblarr(n_elements(ssc_goes_locations->getX()), 3)
    goes_pos_values[*,0] = ssc_goes_locations->getX()
    goes_pos_values[*,1] = ssc_goes_locations->getY()
    goes_pos_values[*,2] = ssc_goes_locations->getZ()
    
    ; set up initial structure for saving the requested location data
    goes_pos_struct = {pos_values: goes_pos_values, coord_sys: ssc_goes_locations->getcoordinatesystem(), $
      time: goes_time_values}
      
    return, goes_pos_struct
end