;+
; PROCEDURE:
;       mvn_swia_diretmag
; PURPOSE:
;       Makes directional E-t spectrograms in the specified pitch angle range from SWIA Coarse data.
; CALLING SEQUENCE:
;       mvn_swia_diretmag,pitch=[150,180]
; INPUTS:
;       None (SWIA data should have been loaded and magnetic field
;       should have been added to SWIA common blocks by 'mvn_swia_add_magf'.)
; KEYWORDS:
;       all optional
;       PITCH: specifies the pitch angle range (Def: [0,30])
;       UNITS: specifies the units ('eflux', 'counts', etc.) (Def: 'eflux')
;       ARCHIVE: uses archive data instead of survey
;       TRANGE: time range to compute directional spectra (Def: all)
;       SUFFIX: suffix of the tplot variable name (Def: e.g., '_pa000-030')
; CREATED BY:
;       Yuki Harada on 2014-11-20
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2015-01-16 12:56:29 -0800 (Fri, 16 Jan 2015) $
; $LastChangedRevision: 16665 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_diretmag.pro $
;-

pro mvn_swia_diretmag, pitch=pitch, units=units, archive=archive, trange=trange, verbose=verbose, suffix=suffix

  common mvn_swia_data

  if not keyword_set(pitch) then pitch=[0,30] else pitch=minmax(abs(pitch))
  if not keyword_set(units) then units='eflux'
  if keyword_set(archive) then time = swica.time_unix else time = swics.time_unix
  if keyword_set(trange) then begin
     idx = where(time ge trange[0] and time le trange[1], idx_cnt)
     if idx_cnt gt 0 then time = time[idx] else begin
        dprint,dlevel=1,verbose=verbose,'No data in the specified time range.'
        return
     endelse
  endif
  if not keyword_set(suffix) then suffix='_pa'+string(pitch[0],f='(i3.3)')+'-'+string(pitch[1],f='(i3.3)')


  center_time = dblarr(n_elements(time))
  energy = fltarr(n_elements(time),48)

  eflux_dir = fltarr(n_elements(time),48)

  for i=0ll,n_elements(time)-1 do begin ;- time loop
     if i mod 1000 eq 0 then dprint,dlevel=1,verbose=verbose,i,' /',n_elements(time)
     d = mvn_swia_get_3dc(time[i],archive=archive)
     d = conv_units(d,units)
     center_time[i] = (d.time+d.end_time)/2.d
     energy[i,*] = d.energy[*,0]
     xyz_to_polar,d.magf,theta=bth,phi=bph
     pa = pangle(d.theta,d.phi,bth,bph)

     idx = where( pa gt pitch[0] and pa lt pitch[1], idx_cnt )
     if idx_cnt gt 0 then begin
        w = d.data * 0.
        w[idx] = 1.
        if strlowcase(units) ne 'counts' then $
           eflux_dir[i,*] = total(d.data*d.domega*w,2)/total(d.domega*w,2) $
        else $
           eflux_dir[i,*] = total(d.data*w,2)
     endif else eflux_dir[i,*] = !values.f_nan

;;      for j=0,d.nenergy-1 do begin ;- energy loop
;;         idx = where( pa[j,*] gt pitch[0] and pa[j,*] lt pitch[1], idx_cnt )
;;         if idx_cnt gt 0 then begin
;;            if strlowcase(units) ne 'counts' then $
;;               eflux_dir[i,j] = total(d.data[j,idx]*d.domega[j,idx]) $
;;                               /total(d.domega[j,idx]) $
;;            else $
;;               eflux_dir[i,j] = total(d.data[j,idx])
;;         endif else eflux_dir[i,j] = !values.f_nan
;;      endfor                     ;- energy loop end
  endfor                        ;- time loop end


  if keyword_set(archive) then type = 'swica' else type = 'swics'

  store_data,'mvn_'+type+'_en_'+units+suffix, $
             data={x:center_time,y:eflux_dir,v:energy}, $
             dlim={spec:1,zlog:1,ylog:1,yrange:minmax(energy),ystyle:1, $
                   ytitle:type+'!c'+suffix+'!cEnergy [eV]', $
                   ztitle:units,datagap:180},verbose=verbose

end
