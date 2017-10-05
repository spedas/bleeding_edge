;+
;PROCEDURE: 
;	MVN_SWIA_PENPROT_CONV
;PURPOSE: 
;	Routine to convert penetrating proton density to solar wind proxy.
;	
;	CAUTION: This routine utilizes a number of assumptions which will 
;	fail at some times - particularly if periapsis is at high SZA. 
;	The results of this routine should be taken as an order-of-magnitude
;	estimate only. 
;
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_PENPROT_CONV
;INPUTS:
;KEYWORDS:
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2017-03-03 17:18:05 -0800 (Fri, 03 Mar 2017) $
; $LastChangedRevision: 22906 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_penprot_conv.pro $
;
;-

pro mvn_swia_penprot_conv, penonly = penonly, oscale = oscale, orbave = orbave, stack = stack

if not keyword_set(oscale) then oscale = 0.03

ecross = [200,500,1000,2000,3000,4000,5000,10000]
csx = [22e-16,17e-16,15e-16,13.5e-16,13.3e-16,13.1e-16,12.9e-16,10e-16]
strip = [0.2e-16,0.7e-16,1.2e-16,1.8e-16,2.4e-16,3.0e-16,3.3e-16,4e-16]

formula = oscale*strip/(csx+strip)

if keyword_set(stack) then begin

	hup = [2.22e-15, 2.0e-15, 1.71e-15, 1.44e-15, 1.32e-15, 1.20e-15, 1.11e-15, 7.75e-16]
	hup = hup/hup[2]

	formula = formula*hup
endif

;formula(0:1) = formula(0:1)*(ecross/1000.)^0.5

if keyword_set(orbave) then begin
	get_data,'npenorb',data = npen
	get_data,'vpenorb',data = vpen
	penonly = 1
endif else begin
	get_data,'npen',data = npen
	get_data,'nbpen',data = nbpen
	get_data,'vpen',data = vpen
endelse


epen = 0.5*1.67e-27*vpen.y*vpen.y*1e6/1.6e-19

conv = interpol(formula,ecross,epen)

if keyword_set(penonly) then begin
	nsc = npen.y/conv
endif else begin
	nsc = (npen.y+nbpen.y)/conv
endelse

store_data,'nsc',data = {x:npen.x,y:nsc}


end