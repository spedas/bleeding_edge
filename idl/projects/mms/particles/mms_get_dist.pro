;+
;Procedure:
;  mms_get_dist
;
;
;Purpose:
;  Retrieve particle distribution structures/pointers from data loaded
;  into tplot. 
;
;
;Calling Sequence:
;  data = mms_get_dist( input_name [,trange=trange] [/times] [/structure] 
;                       [,probe=probe] [,species=species] 
;                       [,instrument=instrument] [,units=units] )
;
;
;Input:
;  input_name:  Name of tplot variable containing particle data (must be original name)
;  single_time: Return a single time nearest to the time specified by single_time (supersedes trange and index)
;  trange:  Optional two element time range
;  times:  Flag to return array of full distribution sample times
;  structure:  Flag to return structures instead of pointer to structures
;
;  probe: specify probe if not present or correct in input_name 
;  species:  specify particle species if not present or correct in input_name
;                e.g. 'hplus', 'i', 'e'
;  instrument:  specify instrument if not present or correct in input_name 
;                  'hpca' or 'fpi'
;  units:  (HPCA only) specify units of input data if not present or correct in input_name
;              e.g. 'flux', 'df_cm'  (note: 'df_km' is in km, 'df_cm' is in cm)
;
;
;Output:
;  return value:  Pointer to structure array or structure array if /structure used.
;                 Array of times if /times is used
;                 0 for any error case
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-04-03 12:46:57 -0700 (Tue, 03 Apr 2018) $
;$LastChangedRevision: 24987 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_get_dist.pro $
;-

function mms_get_dist, tname, index, trange=trange, times=times, structure=structure, $
                       probe=probe, species=species, instrument=instrument, units=units, $
                       data_rate=data_rate, single_time = time_in, level = level, _extra=_extra
    compile_opt idl2, hidden

    if ~undefined(instrument) then instrument = strcompress(instrument, /rem)
    
    if undefined(instrument) then begin
      instrument = 'null'
      if stregex(tname, '^mms[1-4]_hpca_', /bool) then instrument = 'hpca'
      if stregex(tname, '^mms[1-4]_d[ei]s_', /bool) then instrument = 'fpi'
    endif
    
    if ~undefined(units) and instrument eq 'fpi' then begin
      dprint, dlevel = 0, 'Error: units keyword can only be specified for HPCA distributions; units for FPI will be df_cm; returning..'
      return, 0
    endif
    
    if ~undefined(data_rate) and instrument eq 'hpca' then begin
      dprint, dlevel = 0, 'Error: data_rate keyword can only be specified for FPI distributions; data_rate keyword will be ignored.'
    endif
    
    if ~undefined(level) and instrument eq 'hpca' then begin
      dprint, dlevel = 0, 'Error: level keyword can only be specified for FPI distributions; level keyword will be ignored.'
    endif
    
    case strlowcase(instrument) of
      'hpca': return, mms_get_hpca_dist(tname, index, trange=trange, times=times, structure=structure, probe=probe, species=species, units=units, single_time=time_in, _extra=_extra)
      'fpi': return, mms_get_fpi_dist(tname, index, trange=trange, times=times, structure=structure, probe=probe, species=species, single_time=time_in, data_rate=data_rate, level=level, _extra=_extra)
      'null': dprint, dlevel=1, 'Cannot determine instrument from variable name; please specify with INSTRUMENT keyword'
      else: dprint, dlevel=1, 'Unknown instrument: "'+instrument+'"'
    endcase
    
    return, 0
end