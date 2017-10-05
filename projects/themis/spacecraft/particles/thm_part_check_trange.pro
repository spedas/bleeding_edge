

;+
;NAME:
;  thm_part_check_trange
;
;PURPOSE:
;  This routine checks the time ranges of the current ESA and SST  
;  data stored in the common blocks to determine if it covers a
;  particular time range.
;
;CALLING SEQUENCE:
;  bool = thm_part_check_trange(probe, datatype, trange [,sst_cal=sst_cal] [,fail=fail])
;
;KEYWORDS:
;  probe: String or string array specifying the probe
;  datatype: String or string array specifying the type of 
;        particle data requested (e.g. 'peif', 'pseb')
;  trange: Two element array specifying the numeric time range
;  sst_cal: Flag to check data from new SST calibrations
;  fail: Set to named variable to pass out error messages (string)
;
;OUTPUT:
;  1 if current data covers what is requested, 0 otherwise
;
;NOTES: 
;  
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2016-04-05 14:14:33 -0700 (Tue, 05 Apr 2016) $
;$LastChangedRevision: 20726 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_check_trange.pro $
;-
function thm_part_check_trange, probe0, datatype0, trange, sst_cal=sst_cal, use_eclipse_corrections=use_eclipse_corrections

    compile_opt idl2, hidden



  if undefined(probe0) or undefined(datatype0) or undefined(trange) then begin
    dprint, dlevel=0, 'Missing required input; must specify probe, data type, and time range'
    return, 0
  endif

  probe = strlowcase(probe0)
  datatype = strlowcase(datatype0)
  
  ;check probe input
  valid = where( stregex(probe, '[abcde]', /bool), np)
  if np gt 0 then begin
    probe = probe[valid]
  endif else begin
    dprint, dlevel=0, 'No valid probe(s)'
    return, 0
  endelse
  
  ;check data type input
  valid = where( stregex(datatype, '^p[se][ei][rfb]$', /bool), nv)
  if nv gt 0 then begin
    datatype = datatype[valid]
  endif else begin
    dprint, dlevel=0, 'No valid data type(s)'
    return, 0
  endelse

  ;check trange input
  if n_elements(trange) lt 2 then begin
    dprint, dlevel=0, 'Time range must be two elements'
    return, 0
  endif  
  
  trd = time_double(trange)
  
  eclipse = undefined(use_eclipse_corrections) ? 0:use_eclipse_corrections
  
  ;loop over probe and data type
  for j=0, n_elements(probe)-1 do begin
    for i=0, n_elements(datatype)-1 do begin
      
      ;get stored time range
      thm_part_trange, probe[j], datatype[i], get=loaded, sst_cal=sst_cal
      
      if undefined(loaded) then begin
        dprint, dlevel=0, 'Cannot determine state of loaded th'+probe+'_'+datatype+' data.'
        return, 0
      endif
      
      ;check against the stored range
      if trd[0] lt loaded.trange[0] or $
         trd[1] gt loaded.trange[1] then begin
        return, 0
      endif
      
      ;check status of eclipse corrections
      if eclipse ne loaded.eclipse then begin
        return, 0
      endif
      
    endfor
  endfor

  return, 1

end
