;+
; FUNCTION:
;         elf_get_data_availability
;
; PURPOSE:
;         Get start and stop science zone collection data for a
;         given instrument, probe and date
;
; KEYWORDS:
;         tdate: time to be used for calculation
;                (format can be time string '2020-03-20'
;                or time double)
;         probe: probe name, probes include 'a' and 'b'
;         instrument: instrument name, insturments include 'epd', 'fgm', 'mrm'
;
; OUTPUT:
;         data_availability: structure with start times, stop times and science 
;         zone names. Note: mrm data does not have a science zone associated 
;         with it.
;
; EXAMPLE:
;         data_struct=elf_get_data_availability('2020-03-20', probe='a', instrument='epd'
;
;
;VERSION LAST EDITED: lauraiglesias4@gmail.com 05/18/2021
;-
function elf_get_data_availability, trange=trange, instrument=instrument, probe=probe  ;, days = days

  ; initialize parameters
  if undefined(trange) then begin
     print, 'You must provide a time range.'
     return, -1 
  endif
;print, instrument
;stop
 ; if undefined(days) then days = 31
 ; dt = DOUBLE(days)
 ; timespan, time_double(tdate)-dt*86400., dt
 ; trange=timerange()
  dt=time_double(trange[1])-time_double(trange[0])
  timespan, time_double(trange[0]), dt, /sec
  trange=timerange()
;print,time_string(trange)
;stop  
  ;dt = DOUBLE(days)
  ;timespan, time_double(tdate)-dt*86400., dt

  ;trange=timerange()
  ;current_time=systime() 

;  if undefined(instrument) then instrument='epde' else instrument=strlowcase(instrument)
;  if instrument ne 'epd' and instrument ne 'fgm' and $
;    instrument ne 'mrm' then begin
;    print, instrument + ' is not a valid instrument'
;    print, 'Valid instruments include epd, fgm, and mrm.'
;    return, -1
;  endif

  if undefined(probe) then probe='a' else probe=strlowcase(probe)
  if probe ne 'a' and probe ne 'b' then begin
     print, probe+' is not a valid probe name.'
     print, 'Valid probe names are a or b.'
     return, -1
  endif
  sc='el'+probe

  ;------------------
  ; GET DATA
  ;------------------
;  if instrument ne 'mrma' then begin
;print, instrument
;stop
     itimes=get_elf_science_zone_start_end(trange=trange, probe=probe, instrument=instrument)
     sz_starttimes=itimes.starts
     sz_endtimes=itimes.ends
     sz_dt=sz_endtimes-sz_starttimes
     idx=where(sz_dt GT 5, ncnt)
     if ncnt GT 0 then begin
       sz_starttimes=sz_starttimes[idx]
       sz_endtimes=sz_endtimes[idx]
     endif
;print, instrument
;stop

  ;------------------
  ; GET FGM and MRM DATA
  ;------------------
 ; endif else begin

;     elf_load_mrma, probe=probe, trange=trange
;     get_data, sc+'_mrma', data=d

    ; check for MRM collections
;    if ~undefined(d) && size(d,/type) EQ 8 then begin
;      npts=n_elements(d.x)
;      tdiff=d.x[1:npts-1] - d.x[0:npts-2]
;      idx = where(tdiff GT 390., ncnt)   ; note: 600 seconds is an arbitary time
;      append_array, idx, n_elements(d.x)-1 ;add on last element (end time of last sci zone) to pick up last sci zone  
;      if ncnt EQ 0 then begin
;        ; if ncnt is zero then there is only one science zone for this time frame
;        sz_starttimes=[d.x[0]]
;        sz_endtimes=d.x[n_elements(d.x)-1]
;        ts=time_struct(sz_starttimes[0])
;        te=time_struct(sz_endtimes[0])
;      endif else begin  
;        for sz=0,ncnt do begin ;changed from ncnt-1
;          if sz EQ 0 then begin
;            this_s = d.x[0]
;            this_e = d.x[idx[sz]]
;          endif else begin
;            this_s = d.x[idx[sz-1]+1]
;            this_e = d.x[idx[sz]]
;          endelse
;          if instrument EQ 'mrm' then minsize = 20 else minsize = 6
;          if (this_e-this_s) lt minsize then continue
;          append_array, sz_starttimes, this_s
;          append_array, sz_endtimes, this_e
;        endfor
;      endelse
;    endif else begin
      ; no data
   if undefined(itimes) then begin 
      print, 'There is no data for '+instrument+' in specified range '
      return, -1 
   endif
   
;  endelse
  
  ; get position data and convert to SM coordinates
  elf_load_state, probe=probe, trange=trange
  get_data, sc+'_pos_gei', data=dat_gei
  cotrans,sc+'_pos_gei','el'+probe+'_pos_gse',/GEI2GSE
  cotrans,sc+'_pos_gse','el'+probe+'_pos_gsm',/GSE2GSM
  cotrans,sc+'_pos_gsm','el'+probe+'_pos_sm',/GSM2SM ; in SM
  ; check that it exsits
  if not spd_data_exists(sc+'_pos_sm', trange[0],trange[1]) then begin
     print, 'There is no state data '+ ' from '+ time_string(trange)
     return, -1
  endif 
    
  ; get position data to determine whether s/c is ascending or descending
  get_data, sc+'_pos_sm', data=pos   
  ; get latitude of science collection (needed to determine zone)
  elf_mlt_l_lat,sc+'_pos_sm',MLT0=MLT0,L0=L0,lat0=lat0 ;;subroutine to calculate mlt,l,mlat under dipole configuration

  ; Determine which science zone data was collected for  
  for i=0,n_elements(sz_starttimes)-1 do begin
    this_start=sz_starttimes[i]
    this_end=sz_endtimes[i] 
    idx=where(pos.x GE this_start AND pos.x LE this_end, ncnt)
    if ncnt lt 3 then begin
      print, 'There is no state data for start: '+time_string(this_start)+' to '+time_string(this_end)
      idxexclude=i
      continue
    endif
    sz_lat=lat0[idx] 
    sz_L0 = L0[idx]
    sz_MLT = MLT0[idx]
    median_lat=median(sz_lat)
    dlat = sz_lat[1:n_elements(sz_lat)-1] - sz_lat[0:n_elements(sz_lat)-2]
    dL0 = string(sz_L0[0], FORMAT = '%0.1f') +' - ' + string(sz_L0[-1], FORMAT = '%0.1f')
    medMLT = string(sz_MLT[where(sz_MLT eq median(idx, /EVEN))], FORMAT = '%0.1f')

;    if instrument eq 'mrm' then begin
;      sz_name = 'eq' 
;    endif else begin
    if median_lat GT 0 then begin
      if median(dlat) GT 0 then sz_name = 'nasc' else sz_name = 'ndes'
    endif else begin
      if median(dlat) GT 0 then sz_name = 'sasc' else sz_name = 'sdes'
    endelse
; endelse
      
    append_array, sz_names, sz_name
    append_array, sz_dL0s, dL0
    append_array, sz_medMLTs, medMLT
  endfor     
;stop  
  data_availability={starttimes:sz_starttimes, endtimes:sz_endtimes, zones:sz_names, dL: sz_dL0s, medMLT: sz_medMLTs}
  return, data_availability
   
end