;+
;PROCEDURE:
;   plot_science_zone_mlat
;
;PURPOSE:
;   This routine plots the magnetic latitudes whenever data is collected during a science zones
;   
;KEYWORDS: 
;   This was a one off routine but seems useful. Keywords should be added to this routine   
;
;OUTPUT:
;   
;
;AUTHOR:
;v1.0 S.Frey 12-30-03
;-
pro plot_science_zone_mlat

  ; get instrument and state data
  timespan, '2020-06-01', 30.
  tr=timerange()
  elf_load_epd, probe='a', datatype='pef', level='l1', type='nflux', trange=tr
  get_data, 'ela_pef_nflux', data=pef_nflux
  elf_load_state, probe='a', trange=tr
  get_data, 'ela_pos_gei', data=dat_gei
  cotrans,'ela_pos_gei','ela_pos_gse',/GEI2GSE
  cotrans,'ela_pos_gse','ela_pos_gsm',/GSE2GSM
  cotrans,'ela_pos_gsm','ela_pos_sm',/GSM2SM ; in SM

  ; calculate magnetic latitude
  elf_mlt_l_lat,'ela_pos_sm',MLT0=MLT0,L0=L0,lat0=lat0 ;;subroutine to calculate mlt,l,mlat under dipole configuration
  get_data, 'ela_pos_sm', data=elfin_pos
  store_data,'ela_LAT',data={x:elfin_pos.x,y:lat0*180./!pi}
  options,'ela_LAT',ytitle='LAT'
  
  ; set up for plots by science zone
  if (size(pef_nflux, /type)) EQ 8 then begin
    tdiff = pef_nflux.x[1:n_elements(pef_nflux.x)-1] - pef_nflux.x[0:n_elements(pef_nflux.x)-2]
    idx = where(tdiff GT 90., ncnt)   ; note: 90 seconds is an arbitary time
    append_array, idx, n_elements(pef_nflux.x)-1 ;add on last element (end time of last sci zone) to pick up last sci zone
    if ncnt EQ 0 then begin
      ; if ncnt is zero then there is only one science zone for this time frame
      sz_starttimes=[pef_nflux.x[0]]
      sz_min_st=[0]
      sz_endtimes=pef_nflux.x[n_elements(pef_nflux.x)-1]
      sz_min_en=[n_elements(pef_nflux.x)-1]
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
        if (this_e-this_s) lt 60. then continue
        append_array, sz_starttimes, this_s
        append_array, sz_endtimes, this_e
        append_array, sz_min_st, sidx
        append_array, sz_min_en, eidx
      endfor
    endelse
  endif

  for i=0,n_elements(sz_starttimes)-1 do begin
     tdiff=abs(elfin_pos.x - sz_starttimes[i])
     mindiff=min(tdiff, minidx)
     append_array, start_lats, lat0(minidx)*180./!pi
     tdiff=abs(elfin_pos.x - sz_endtimes[i])
     mindiff=min(tdiff, minidx)
     append_array, stop_lats, lat0(minidx)*180./!pi
  endfor

  t0=time_double('2020-06-01')
  these_starts=(sz_starttimes-t0)/86400.
  idx=where(start_lats GT 0, ncnt)  
  plot, these_starts[idx], start_lats[idx], color=255
  these_stops=(sz_stoptimes-t0)/86400.
  idx=where(stop_lats GT 0, ncnt)
  oplot, these_stops[idx], stop_lats[idx]
  
stop
end