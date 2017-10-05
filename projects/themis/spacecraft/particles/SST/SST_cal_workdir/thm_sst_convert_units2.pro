
;+
;NAME:
; thm_sst_convert_units2
;PURPOSE:
;
;  This routine converts input data into the desired physical units 
;  It is used as a callback function by ssl_general routines like moments_3d/conv_units
;  It will mutate the contents of the struct that is passed as an argument.
;  
;Inputs:
;  data: data struct that is being converted, this structure will have its data mutated
;  units: string identifying the desired output units
;  other_data: Proper calibration of the SST requires removal of ion & electron cross-contamination at high energies.  If this argument contains the associated struct from
;  the opposite species, cross contamination will be removed.
;  
;Outputs:
;  scale: scale factor that was used to convert the data into the desired format, should have dimensions that match the data
;  
;  
;SEE ALSO:
;  thm_sst_energy_cal2
;  moments_3d
;  conv_units
;  thm_convert_esa_units
;  
;NOTES:
;  This code is based heavily on thm_convert_esa_units.  Looking there should be helpful in understanding this code.
;
;  
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2013-09-06 18:19:42 -0700 (Fri, 06 Sep 2013) $
;$LastChangedRevision: 12970 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/SST_cal_workdir/thm_sst_convert_units2.pro $
;-


pro thm_sst_convert_units2,data,units,scale=scale

;so scale gets passed back even if units = data.units_name
scale = 1.d

if n_params() eq 0 then return

if strupcase(units) eq strupcase(data.units_name) then return

;Version checks all bits, accounts for issues due to stuck attenuator on THD
if in_set(strlowcase(tag_names(data)),'att') then begin
  atten = thm_sst_atten_scale(data.atten,dimen(data.data),scale_factors=data.att)
endif else begin
  atten = thm_sst_atten_scale(data.atten,dimen(data.data))
endelse

if in_set(strlowcase(tag_names(data)),'eff') then begin
  eff = data.eff
endif else begin
  eff = 1.
endelse

denergy = data.denergy
energy = data.energy           	; in eV                (ne,nbins)
n_e = data.nenergy		; number of energies
nbins=data.nbins		; number of bins

gf = data.geom_factor * atten * data.gf * denergy * data.eff

dt = data.integ_t
mass = data.mass
dead = data.deadtime		; dead time in seconds/count

case strupcase(data.units_name) of
'COMPRESSED': scale = 1.d
'COUNTS' :  scale = 1.
'RATE'   :  scale = 1.d* dt
'EFLUX'  :  scale = 1.d * dt * gf / energy
'FLUX'   :  scale = 1.d * dt * gf
'DF'     :  scale = 1.d * dt * gf * (energy * 2./mass/mass*1e5 )
else: begin
    dprint,'Unknown starting units: ',data.units_name
   return
 end
endcase


tmp = data.data
if strupcase(data.units_name) eq 'COMPRESSED' then begin ;decompress if input units are counts
  tmp = thm_part_decomp16(byte(tmp))
endif

;convert back to counts
tmp = scale*tmp 

;take out the dead time correction
if strupcase(data.units_name) ne 'COUNTS' and strupcase(data.units_name) ne 'RATE' and strupcase(data.units_name) ne 'COMPRESSED' then begin
  tmp = tmp / (1+(dead/dt)*tmp)
endif

case strupcase(units) of
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

; dead time correction if not counts or rate
if strupcase(units) ne 'COUNTS' and strupcase(units) ne 'RATE' then begin
	denom = 1.- dead*tmp/dt
	idx = where(denom lt .2,count)
	if count gt 0 then begin
		dprint, min(denom,ind)
		dprint, ' Error: sst_convert_units dead time error.'
		dprint, ' Dead time correction limited to x5 for ',count,' bins'
		dprint, ' Time= ',time_string(data.time,/msec)
		denom[idx] = !VALUES.F_NAN
	endif
	
	denom = .2 > denom < 1.
	
endif else begin
  denom = 1.
endelse

;scale to new units
data.data = scale * tmp/denom 

idx = where(~finite(data.data),c)

if c gt 0 then begin
  data.data[idx] = 0
endif

data.units_name=units

return
end



