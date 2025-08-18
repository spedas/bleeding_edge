pro thm_sst_convert_units,data,units,scale=scale

;so scale gets passed back even if units = data.units_name
scale = 1.d

if n_params() eq 0 then return

if strupcase(units) eq strupcase(data.units_name) then return

;Previous version only checks least significant bit, doesn't clearly handle ambiguous cases.
;atten = data.atten ? 1/64. : 1.  ;
  
;New version checks all bits, accounts for issues due to stuck attenuator on THD
atten = thm_sst_atten_scale(data.atten,dimen(data.data))

denergy = data.denergy
energy = data.energy           	; in eV                (ne,nbins)
n_e = data.nenergy		; number of energies
nbins=data.nbins		; number of bins
gf = data.geom_factor * atten * data.gf * denergy  ;*data.eff
dt = data.integ_t
;dt_arr=data.dt_arr		; #dt*#anodes per bin for rate and dead time corrections
mass = data.mass
;dead = data.dead		; dead time, (sec) A111

case strupcase(data.units_name) of
'COMPRESSED' :  scale = 1.
'COUNTS' :  scale = 1.
;'RATE'   :  scale = dt  ;*dt_arr
;'EFLUX'  :  scale = gf
;'FLUX'   :  scale = gf * energy
;'DF'     :  scale = gf * energy^2 * 2./mass/mass*1e5
else: begin
        dprint,'Unknown starting units: ',data.units_name
	return
      end
endcase

; convert to COUNTS
tmp=data.data
if strupcase(data.units_name) eq 'COMPRESSED' then tmp=cc3d(byte(tmp))
tmp = scale * tmp

; take out dead time correction
;if strupcase(data.units_name) ne 'COUNTS' and strupcase(data.units_name) ne 'RATE' and strupcase(data.units_name) ne 'COMPRESSED' then $
;	tmp = round(dt*tmp/(1.+tmp*dead/dt_arr))

de_e = denergy/energy

scale = 0
case strupcase(units) of
'COMPRESSED' :  scale = 1.
'COUNTS' :  scale = 1.
'RATE'   :  scale = 1./dt
'EFLUX'  :  scale = 1./dt / gf * energy
'FLUX'   :  scale = 1./dt / gf
'DF'     :  scale = 1./dt / gf /  (energy * 2./mass/mass*1e5 )
else: begin
        message,'Undefined units: '+units
        return
      end
endcase

;; dead time correct data if not counts or rate
;if strupcase(units) ne 'COUNTS' and strupcase(units) ne 'RATE' and strupcase(units) ne 'COMPRESSED' then begin
;	denom = 1.- dead/dt_arr*tmp/dt
;;	print,min(denom)
;	void = where(denom lt .1,count)
;	if count gt 0 then begin
;		print,min(denom,ind)
;		denom = denom>.1
;		print,' Error: convert_peace_units dead time error.'
;		print,' Dead time correction limited to x10 for ',count,' bins'
;		print,' Time= ',time_to_str(data.time,/msec)
;	endif
;	tmp2 = tmp/denom
;endif else tmp2 = tmp

; scale to new units
data.units_name = units
if find_str_element(data,'ddata') ge 0 then data.ddata = scale * tmp2^.5
;if strupcase(units) eq 'COMPRESSED' then begin
;	ind=where(tmp2 ge 0.,npts)
;	ntmp=n_elements(tmp2)
;	if npts gt 0 then begin
;		for i=0,npts do begin
;			minval=min(abs(cc3d-tmp2(ind(i))),jj)
;			tmp2(ind(i))=jj
;		endfor
;	endif
;	if npts ne ntmp then begin
;		tmp3=intarr(ntmp)
;		if npts gt 0 then tmp3(ind)=1
;		ind2=where(tmp3 eq 0)
;		tmp2(ind2)=255
;	endif
;endif

data.data = scale * tmp  ;2

return
end



