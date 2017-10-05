;+
; PROCEDURE:
;       kgy_pace_convert_units
; PURPOSE:
;       converts the units for a PACE 3d data structure
; CALLING SEQUENCE:
;       kgy_pace_convert_units, dat, units
; INPUTS:
;       dat: 3d data structure for ESA-S1/ESA-S2/IMA/IEA
;       units: units to convet the structure to
; KEYWORDS:
;       scale: returns an array of conversion factors used
;       nan2zero: if set, NaN and infinite in data -> 0 and bins = 0
; NOTES:
;       This procedure does NOT include deadtime corrections.
;       Use /cntcorr keyword in kgy_*_get3d function to correct counts.
; CREATED BY:
;       Yuki Harada on 2014-06-30
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2016-09-09 11:33:47 -0700 (Fri, 09 Sep 2016) $
; $LastChangedRevision: 21810 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_pace_convert_units.pro $
;-

pro kgy_pace_convert_units, dat, units, scale=scale, nan2zero=nan2zero

if n_params() eq 0 then return
if strupcase(units) eq strupcase(dat.units_name) then begin
   if not keyword_set(nan2zero) then return $
   else begin
      idx0 = where(finite(dat.data) ne 1 , idx0_cnt)
      if idx0_cnt gt 0 then begin
         dat.data[idx0] = 0
         dat.bins[idx0] = 0
      endif
      return
   endelse
endif

energy = dat.energy
gf = dat.gfactor * dat.eff
dt = dat.integ_t
mass = dat.mass

case strupcase(dat.units_name) of 
   'COUNTS' :  scale = 1.d           ; Counts                        
   'RATE'   :  scale = 1.d*dt        ; Counts/sec
   'CRATE'  :  scale = 1.d*dt        ; Counts/sec (no deadtime corr.)
   'EFLUX'  :  scale = 1.d*dt*gf     ; eV/cm^2-sec-sr-eV
   'FLUX'   :  scale = 1.d*dt*gf * energy ; 1/cm^2-sec-sr-eV
   'DF'     :  scale = 1.d*dt*gf * energy^2 * 2./mass/mass*1e5 ; 1/(cm^3-(km/s)^3)
else: begin
   dprint, 'Unknown starting units: ',dat.units_name
   return
end
endcase

case strupcase(units) of
   'COUNTS' :  scale = scale * 1.d
   'RATE'   :  scale = scale * 1.d/(dt)
   'CRATE'  :  scale = scale * 1.d/(dt) ; no deadtime corr.
   'EFLUX'  :  scale = scale * 1.d/(dt * gf)
   'FLUX'   :  scale = scale * 1.d/(dt * gf * energy)
   'DF'     :  scale = scale * 1.d/(dt * gf * energy^2 * 2./mass/mass*1e5 )
else: begin
   message,'Undefined units: '+units
   return
end
endcase

; scale to new units
dat.units_name = units
dat.data = dat.data * scale

if keyword_set(nan2zero) then begin
   idx0 = where(finite(dat.data) ne 1 , idx0_cnt)
   if idx0_cnt gt 0 then begin
      dat.data[idx0] = 0
      dat.bins[idx0] = 0
   endif
endif

return
end
