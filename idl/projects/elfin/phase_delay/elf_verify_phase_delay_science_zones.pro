function elf_verify_phase_delay_science_zones, startdate=startdate, probe=probe
; this routines checks each science zone for a matching phase delay.


missing_zone=['']
no_zone=['']
diffs=[1]

  ; download and read the phase delay file
  phase_delays=elf_get_phase_delays(no_download=nodownload, probe=probe, $
    instrument=instrument)

  starttimes=phase_delays.starttimes
  endtimes=phase_delays.endtimes

  ; get epd data
  thisst=time_double(startdate) 
  thisen=thisst + 86400.
  thistr = [thisst, thisen]
print, time_string(thistr)
    elf_load_epd, probes=probe, trange=thistr, datatype='pef', level='l1', type='nflux', no_download=no_downlaod
    get_data, 'el'+probe+'_pef_nflux', data=pef_nflux
    if (size(pef_nflux, /type)) NE 8 then begin
      undefine, pef_nflux
      del_data, '*.*'
      return, -1
    endif
    ; figure out science zones
    if n_elements(pef_nflux.x) GT 2 then begin
      tdiff = pef_nflux.x[1:n_elements(pef_nflux.x)-1] - pef_nflux.x[0:n_elements(pef_nflux.x)-2]
      idx = where(tdiff GT 270., ncnt)
      append_array, idx, n_elements(pef_nflux.x)-1 ;add on last element (end time of last sci zone) to pick up last sci zone
    endif else begin
    ; ********* TO DO: might need to account for n_elements(pef_nflux.x) EQ 2
      ncnt=0
    endelse
    if ncnt EQ 0 then begin
      ; if ncnt is zero then there is only one science zone for this time frame
      sz_starttimes=[pef_nflux.x[0]]
      sz_endtimes=pef_nflux.x[n_elements(pef_nflux.x)-1]
      ts=time_struct(sz_starttimes[0])
      te=time_struct(sz_endtimes[0])
    endif else begin
      for sz=0,ncnt do begin ;changed from ncnt-1
        if sz EQ 0 then begin
          this_s = pef_nflux.x[0]
          sidx = 0
          this_e = pef_nflux.x[idx[sz]]
          eidx = idx[sz]
        endif else begin
          this_s = pef_nflux.x[idx[sz-1]+1]
          sidx = idx[sz-1]+1
          this_e = pef_nflux.x[idx[sz]]
          eidx = idx[sz]
        endelse
        if (this_e-this_s) lt 15. then continue ; ignore if lt 3 spins
        append_array, sz_starttimes, this_s
        append_array, sz_endtimes, this_e
      endfor ; end of sz determination zone loop
    endelse
    if undefined(sz_starttimes) then begin
       print, 'No science zones'
       stop
    endif 
    num_szs=n_elements(sz_starttimes)

print, 'finished sci zone determination'
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; MAIN LOOP for science zone and phase delay validation
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    for j=0,num_szs-1 do begin ;changed from 0,nplots-1

      sz_tr=[sz_starttimes[j],sz_endtimes[j]]   ; add 3 seconds to ensure that full spin periods are loaded

      ; check phase delay start time array
      idx = where(starttimes GE sz_tr[0]-15, ncnt)
      if ncnt GT 0 then begin
        print, time_string(sz_tr[0])
        print, time_string(starttimes[idx[0]])
        diff=abs(sz_tr[0] -  starttimes[idx[0]])
print, diff
        if diff GT 60. then begin
          print, 'No sci zone found for'
          print, time_string(sz_tr)
          help, diff
          missing_zone=[missing_zone, time_string(sz_tr[0])]
          diffs=[diffs,diff]
          print, 'Error'
        endif
      endif else begin
        print, 'No match or at end of science zones'
        print, time_string(sz_tr)
        help, diff
        print, 'Error'
;****** TO DO: should this be written to missing file ?
;        append_array, no_sci_zones, time_string(sz_tr)
;        append_array, no_diffs, diff
;        stop
        ; write to file
      endelse
    endfor ; phase delay sci zone loop
    undefine, pef_nflux
    del_data,  'el'+probe+'_pef_nflux'

    if ~undefined(missing_zone) and ~undefined(diffs) then begin
 ;   if ~undefined(mz) and ~undefined(d) then begin
       missing_struc={zone: missing_zone, diff:diffs}
 ;      missing_struc={zone: mz, diff:df}
 ;help, missing_struc
    return, missing_struc
    endif else begin
       return, -1
    endelse
end
