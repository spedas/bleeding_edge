;+
;PROCEDURE: 
;	MVN_SWIA_CONVERT_UNITS
;PURPOSE: 
;	Convert the units for a SWIA 3d data structure (fine or coarse)
;	Typically called by the wrapper routine 'Conv_units' 
;	Note that my routine works a bit differently from Wind/THEMIS heritage
;	I use the dt_arr field to deal with summed time steps, instead of adding
;	geometric factors
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE: 
;	MVN_SWIA_CONVERT_UNITS, Data, Units, SCALE=SCALE
;INPUTS: 
;	Data: A 3d data structure for SWIA (coarse or fine)
;	Units: Units to conver the structure to
;KEYWORDS:
;	SCALE: Returns an array of conversion factors used
;OUTPUTS:
;	Returns the same data structure in the new units
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2013-06-18 21:19:24 -0700 (Tue, 18 Jun 2013) $
; $LastChangedRevision: 12551 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_convert_units.pro $
;
;-

pro mvn_swia_convert_units, data, units, scale=scale

compile_opt idl2

if n_params() eq 0 then return

if strupcase(units) eq strupcase(data.units_name) then return

energy = data.energy           ; in eV                (ne,nbins)
n_e = data.nenergy		; number of energies
nbins=data.nbins		; number of bins
gf = data.geom_factor*data.gf*data.eff
dt = data.integ_t
dt_arr=data.dt_arr		; #dt*#anodes per bin for rate and dead time corrections
mass = data.mass
dead = data.dead		; dead time, (sec) A121

if strupcase(data.units_name) eq 'COUNTS' then rate = data.data/(dt*dt_arr) else rate = 0.
;only dead time correct if going from counts

dtc = 1.-rate*dead
w =where(dtc lt 0.2,c)
if c ne 0 then dtc[w] = !values.f_nan

case strupcase(data.units_name) of 
'COUNTS' :  scale = 1.d						; Counts			
'RATE'   :  scale = 1.d*dt*dt_arr					; Counts/sec
'CRATE'  :  scale = 1.d*dtc*dt*dt_arr					; Counts/sec, deadtime corrected
'EFLUX'  :  scale = 1.d*dtc*dt*dt_arr*gf 				; eV/cm^2-sec-sr-eV
'FLUX'   :  scale = 1.d*dtc*dt*dt_arr*gf * energy			; 1/cm^2-sec-sr-eV
'DF'     :  scale = 1.d*dtc*dt*dt_arr*gf * energy^2 * 2./mass/mass*1e5	; 1/(cm^3-(km/s)^3)
else: begin
        dprint, 'Unknown starting units: ',data.units_name
	return
      end
endcase


case strupcase(units) of
'COUNTS' :  scale = scale * 1.d
'RATE'   :  scale = scale * 1.d/(dtc * dt * dt_arr)
'CRATE'  :  scale = scale * 1.d/(dtc * dt * dt_arr)
'EFLUX'  :  scale = scale * 1.d/(dtc * dt * dt_arr * gf)
'FLUX'   :  scale = scale * 1.d/(dtc * dt * dt_arr * gf * energy)
'DF'     :  scale = scale * 1.d/(dtc * dt * dt_arr * gf * energy^2 * 2./mass/mass*1e5 )
else: begin
        message,'Undefined units: '+units
        return
      end
endcase


; scale to new units
data.units_name = units


data.data = data.data * scale

return
end



