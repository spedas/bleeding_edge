pro thm_convert_esa_units, data, units, scale=scale, fractional_counts=fractional_counts, zero_dead_time = zero_dead_time, _extra=_extra

;so scale gets passed back even if units = data.units_name
scale = 1.d

cc3d=findgen(256)

if n_params() eq 0 then return

if strupcase(units) eq strupcase(data.units_name) then return

energy = data.energy           	; in eV                (ne,nbins)
n_e = data.nenergy		; number of energies
nbins=data.nbins		; number of bins
gf = data.geom_factor*data.gf*data.eff
dt = data.integ_t
dt_arr=data.dt_arr		; #dt*#anodes per bin for rate and dead time corrections
mass = data.mass
If(keyword_set(zero_dead_time)) Then dead = 0.0 $
Else dead = data.dead		; dead time, (sec) A121

case strupcase(data.units_name) of 
'COMPRESSED' :  scale = 1.d						
'COUNTS' :  scale = 1.d							; #/sample		
'RATE'   :  scale = 1.d*dt*dt_arr					; #/sec
'CRATE'  :  scale = 1.d*dt_arr					; #/sec, corrected for dead time rate, changed for consistency with eflux, flux and df, which get un-deadtime corrected later with dt included, jmm, 10-may-2011
'EFLUX'  :  scale = 1.d*gf 						; eV/cm^2-sec-sr-eV
'FLUX'   :  scale = 1.d*gf * energy					; #/cm^2-sec-sr-eV
'DF'     :  scale = 1.d*gf * energy^2 * 2./mass/mass*1e5		; 1/(cm^3-(km/s)^3)
else: begin
        dprint, 'Unknown starting units: ',data.units_name
	return
      end
endcase

; convert to COUNTS
tmp=data.data
if strupcase(data.units_name) eq 'COMPRESSED' then tmp=cc3d(byte(tmp))
tmp = scale * tmp

; take out dead time correction
if strupcase(data.units_name) ne 'COUNTS' and strupcase(data.units_name) ne 'RATE' and strupcase(data.units_name) ne 'COMPRESSED' then begin
  ; allow data to NOT be rounded to the nearest whole count (aaflores 2013-02-25)
  ;changed this to the default because rounding causes quantization artifacts in many cases(interpolation, flux->eflux, etc...) (pcruce 2013-07-25)
  if n_elements(fractional_counts) eq 0 || keyword_set(fractional_counts) then begin
    tmp = (dt*tmp/(1.+tmp*dead/dt_arr))
  endif else begin  
  	tmp = round(dt*tmp/(1.+tmp*dead/dt_arr))
  endelse
endif


scale = 0
case strupcase(units) of
'COMPRESSED' :  scale = 1.
'COUNTS' :  scale = 1.d
'RATE'   :  scale = 1.d/(dt * dt_arr)
'CRATE'  :  scale = 1.d/(dt * dt_arr)
'EFLUX'  :  scale = 1.d/(dt * gf)
'FLUX'   :  scale = 1.d/(dt * gf * energy)
'DF'     :  scale = 1.d/(dt * gf * energy^2 * 2./mass/mass*1e5 )
else: begin
        message,'Undefined units: '+units
        return
      end
endcase
; dead time correct data if not counts or rate
if strupcase(units) ne 'COUNTS' and strupcase(units) ne 'RATE' and strupcase(units) ne 'COMPRESSED' then begin
	denom = 1.- dead/dt_arr*tmp/dt
	void = where(denom lt .1,count)
	if count gt 0 then begin
		dprint,dlevel=1,min(denom,ind)
		denom = denom > .1 
		dprint,dlevel=1,' Error: convert_peace_units dead time error.'
		dprint,dlevel=1,' Dead time correction limited to x10 for ',count,' bins'
		dprint,dlevel=1,' Time= ',time_string(data.time,/msec)
	endif
	tmp2 = tmp/denom
endif else tmp2 = tmp

;Why is this here?, 2014-12-05, jmm
;tmp2=tmp

; scale to new units
data.units_name = units
if find_str_element(data,'ddata') ge 0 then data.ddata = scale * tmp2^.5
if strupcase(units) eq 'COMPRESSED' then begin
	ind=where(tmp2 ge 0.,npts)
	ntmp=n_elements(tmp2)
	if npts gt 0 then begin
		for i=0L,npts-1 do begin
			minval=min(abs(cc3d-tmp2[ind[i]]),jj)
			tmp2[ind[i]]=jj
		endfor
	endif
	if npts ne ntmp then begin
		tmp3=intarr(ntmp) 
		if npts gt 0 then tmp3[ind]=1 
		ind2=where(tmp3 eq 0)
		tmp2[ind2]=255
	endif
endif

data.data = scale * tmp2

return
end



