;+
;PROCEDURE: 
;	MVN_SWIA_MOMENT_DECOM
;PURPOSE: 
;	Decompress the floating point moment values 
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_MOMENT_DECOM, Mom, Momout
;INPUTS: 
;	Mom: An array of floating point moments stored in compressed form
;OUTPUTS:
;	Momout: Returns the floating point version of Mom
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2013-06-18 21:19:24 -0700 (Tue, 18 Jun 2013) $
; $LastChangedRevision: 12551 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_moment_decom.pro $
;
;-

pro mvn_swia_moment_decom, mom, momout

compile_opt idl2

momout = float(mom)

sign = mvn_swia_subword(mom,bit1 = 15,bit2 = 15)
x = mvn_swia_subword(mom,bit1 = 14,bit2 = 0)
w = where(x lt '400'X,nw)
if nw gt 0 then momout[w] = x[w]

w = where(x ge '400'X,nw)

if nw gt 0 then begin
	exp = mvn_swia_subword(x[w],bit1 = 15,bit2 = 9) - 1
	man = mvn_swia_subword(x[w],bit1 = 8,bit2 = 0) + '200'X
	momout[w] = man*2.0^float(exp)
endif

momout = momout*(-1)^sign

end
	