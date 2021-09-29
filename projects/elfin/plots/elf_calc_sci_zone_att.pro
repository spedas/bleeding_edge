;+
; FUNCTION:
;         elf_calc_sci_zone_att
;
; PURPOSE:
;         Calculates the science attitude vector and determines which auroral crossing
;         (science zone name)
;
; KEYWORDS:
;         trange: time frame to be used for calculation
;                (format can be time string '2020-03-20'
;                or time double). Example: trange=['2020-03-20;,'2020-03-21']
;         probe: probe name, probes include 'a' and 'b'
;         lat: lattitude (used to determine which zone)
;         lshell: lshell used to determine whether IBO or OBO
;         obo: set this keyword to get inner belt att
;
; OUTPUT:
;         creates a tplot variable 'el'+probe+'_spin_att_ang' that contains the following
;          data={x:times, y:colats, z:zone_names}
;
;-
pro elf_calc_sci_zone_att, probe=probe, trange=trange, lat=lat, lshell=lshell, ibo=ibo

  ; initialize parameters if needed
  if undefined(probe) then probe ='a' else probe=strlowcase(probe)
  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return
  endif
  if ~undefined(trange) && n_elements(trange) eq 2 then trange = timerange(trange) else trange = timerange()

  ; get position in gsm coordinates
  elf_load_state, probe=probe, suffix='_tmp', trange=trange
  cotrans,  'el'+ probe + '_pos_gei_tmp',  'el'+ probe + '_pos_gse_tmp', /gei2gse
  cotrans,  'el'+ probe + '_pos_gse_tmp',  'el'+ probe + '_pos_gsm_tmp', /gse2gsm
  get_data, 'el'+ probe + '_pos_gsm_tmp', data=pos_gsm

  ; Get igrf field and convert to gei
  tt89,'el'+ probe + '_pos_gsm_tmp', kp=1,newname='el'+ probe + '_igrf_gsm_tmp',/igrf_only
  cotrans, 'el'+ probe + '_igrf_gsm_tmp', 'el'+ probe + '_igrf_gse_tmp', /gsm2gse
  cotrans, 'el'+ probe + '_igrf_gse_tmp', 'el'+ probe + '_igrf_gei_tmp', /gse2gei

  ; interpolate to attitude resolution
  get_data, 'el'+ probe + '_igrf_gei_tmp', data=d, dlimits=dl, limits=l
  store_data, 'el'+ probe + '_igrf_gei_tmp', data={x: d.x[0:*:60], y: d.y[0:*:60,*]}, dlimits=dl, limits=l

  ; normalize
  get_data, 'el'+ probe + '_igrf_gei_tmp', data=d, dlimits=dl, limits=l
  magd=sqrt(d.y[*,0]^2+d.y[*,1]^2+d.y[*,2]^2)
  d.y[*,0]=d.y[*,0]/magd
  d.y[*,1]=d.y[*,1]/magd
  d.y[*,2]=d.y[*,2]/magd
  store_data, 'el'+ probe + '_igrf_gei_tmp', data=d, dlimits=dl, limits=l

  ; calculate spin angle
  tdotp,'el'+ probe + '_igrf_gei_tmp','el'+probe+'_att_gei_tmp',newname='el'+ probe + '_dotprod'
  get_data, 'el'+ probe + '_dotprod',data=dotprod
  colat_dsl = 90.-acos(dotprod.y)*180/!pi

  ; restore original resolution (1 second)
  store_data, 'el'+probe+'_colat_dsl', data={x:pos_gsm.x, y:interp(colat_dsl, dotprod.x, pos_gsm.x)}
  get_data, 'el'+probe+'_colat_dsl', data=colat
  npts=n_elements(colat.x)

  ; Find auroral crossings (lat is magnetic lat)
  if keyword_set(ibo) then begin
    lhigh=3.2
    llow=1.27
  endif else begin
    lhigh=18
    llow=3.25
  endelse
  idx = where(abs(lshell) GE llow and abs(lshell) LE lhigh, ncnt)
  if ncnt GT 0 then begin
    find_interval, idx, ist, ien
    nidx=n_elements(ien)-1
    if ien[nidx] GE npts then ien[nidx]=ien[nidx]-1
    for i=0,n_elements(ist)-1 do begin
      ; determine whether ascending or descending
      this_time=colat.x[ist[i]:ien[i]]
      this_lat=lat[ist[i]:ien[i]]
      this_colat=colat.y[ist[i]:ien[i]]
      npts = n_elements(this_time)
      diff=this_lat[npts-1] - this_lat[0]
      ; find the midpoint
      mididx=npts/2
      ; North zones
      if this_lat[mididx] GT 0 then begin
        if diff GT 0 then append_array, zone_names, 'NA' else $
          append_array, zone_names, 'ND'
      endif else begin
        ; South Zones
        if diff GT 0 then append_array, zone_names, 'SA' else $
          append_array, zone_names, 'SD'
      endelse
      append_array, colats, this_colat[mididx]
      append_array, times, this_time[mididx]
    endfor
    store_data, 'el'+probe+'_spin_att_ang', data={x:times, y:colats, z:zone_names}
  endif else begin
    print, 'Error calculating science attitude vector. There is no data in the auroral zones.'
  endelse

end