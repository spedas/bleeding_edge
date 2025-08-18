;+
;PROCEDURE: 
;	MVN_SWIA_PENPROT
;PURPOSE: 
;	Routine to determine density and velocity of penetrating protons at periapsis
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_PENPROT, REG = REG
;INPUTS:
;KEYWORDS:
;	REG: region structure from 'mvn_swia_regid'
;	NPO: number of determinations per orbit
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2015-04-06 13:11:09 -0700 (Mon, 06 Apr 2015) $
; $LastChangedRevision: 17244 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_penprot.pro $
;
;-

pro mvn_swia_penprot, reg = reg, npo = npo

mass = 0.0104389*1.6e-22
Const = (mass/(2.*1.6e-12))^0.5

common mvn_swia_data

if not keyword_set(npo) then npo = 1

if keyword_set(reg) then begin
	ureg = interpol(reg.y(*,0),reg.x,swis.time_unix+2.0)
	w = where(ureg eq 4)
	uswis = swis(w)
endif else begin
	uswis = swis
endelse

times = uswis.time_unix
energies = info_str(uswis.info_index).energy_coarse
denergies = energies*info_str(uswis.info_index).deovere_coarse
attens = uswis.atten_state

orb = mvn_orbit_num(time = times)
orb = floor((orb+0.5)*npo)  ; deal with silly orbit convention

mino = min(orb)
maxo = max(orb)
norb = maxo-mino+1

nout = fltarr(norb)
vout = fltarr(norb)
tout = dblarr(norb)

for i = 0,norb-1 do begin
	w = where(orb eq (mino+i) and attens ne 2,nw)		;Attenuator Closed Screws Up
	if nw gt 10 then begin
		spec = total(uswis(w).data,2,/nan)/nw
		energy = total(energies(*,w),2,/nan)/nw
		denergy = total(denergies(*,w),2,/nan)/nw
		
		wr = where(energy gt 200 and energy lt 4000)
		spec = spec-min(spec(wr)) > 0
		nout(i) = Const*2*sqrt(2)*!pi*total(denergy(wr)*energy(wr)^(-1.5)*spec(wr))

		maxc = max(spec(wr),maxi)
		eout = energy(wr(maxi))
		vout(i) = sqrt(2*eout*1.6e-19/1.67e-27)/1e3
		tout(i) = mean(uswis(w).time_unix,/double,/nan)
	endif
endfor

w = where(tout ne 0)

store_data,'npen',data = {x:tout(w),y:nout(w)}
store_data,'vpen',data = {x:tout(w),y:vout(w)}

end