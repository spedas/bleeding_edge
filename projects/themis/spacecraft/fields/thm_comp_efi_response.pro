;+
;	Procedure:
;		thm_comp_efi_response
;
;	Purpose:
;		Compute the voltage gain (magnitude only) as a function of frequency
;	for a given THEMIS EFI sensor (SPB or AXB).
;
;	Calling Sequence:
;	thm_comp_efi_response, sensor, ff, resp

;	Arguements:
;		sensor	STRING, one of SPB or AXB.
;		ff	FLOAT[ N], array of frequencies at which to compute the sensor response.
;		resp	COMPLEX[ N], array of voltage gain vs. frequency.
;
;	Notes:
;	-- none.
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2012-05-22 11:57:35 -0700 (Tue, 22 May 2012) $
; $LastChangedRevision: 10450 $
; $URL $
;-
pro thm_comp_efi_response, sensor, ff, resp,rsheath=rsheath,complex_response=complex_response


case strupcase( sensor) of
	'SPB':	begin
;		rs = 50.e6		; old value of sheath resistance, ohm. jmm, 2012-05-21
		rs = 5.e6		; sheath resistance, ohm. (can overridde by keyword)
		cs = 10.e-12	; sheath capacitance, F.
		re = 100.e3		; ESD protection resistor, ohm.
		ce = 10.e-12	; ESD  bypass capacitor, F.
		ri = 1.e12		; op-amp input resistance, ohm.
		ci = 7.e-12		; op-amp effective input capacitance, F.
		ro = 100.		; series output resistance, ohm.
		ll = 25.		; cable length, m.
		dc_dl = 75.e-12	; cable capacitance, F/m.
		dr_dl = 1.5		; cable resistance, ohm/m.
		rl = 100.e3		; load resistance, ohm.
	end
	'AXB':	begin
;		rs = 50.e6		; old value of sheath resistance, ohm. jmm, 2012-05-21
		rs = 5.e6		; sheath resistance, ohm. (can overridde by keyword)
		cs = 5.e-12	; sheath capacitance, F.
		re = 100.e3		; ESD protection resistor, ohm.
		ce = 10.e-12	; ESD  bypass capacitor, F.
		ri = 1.e12		; op-amp input resistance, ohm.
		ci = 7.e-12		; op-amp effective input capacitance, F.
		ro = 100.		; series output resistance, ohm.
		ll = 3.			; cable length, m.
		dc_dl = 75.e-12	; cable capacitance, F/m.
		dr_dl = 1.5		; cable resistance, ohm/m.
		rl = 100.e3		; load resistance, ohm.

	end
	else:	begin
		dprint, string( sensor, format='(A,X,"sensor not recognized; NaN response will be returned.")')
		resp = ff + !values.f_nan
		return
	end
endcase
if keyword_set(rsheath) then rs=rsheath

; compute cable resistance and capacitance from input parameters.
cc = ll*dc_dl
rc = ll*dr_dl

; compute voltage gain as a function of frequency.
ww = 2.0*!dpi*ff	; double, rad/s.
ss = dcomplex( 0.0, 1.0)*ww	; j*omega, rad/s.

ys = 1.0/rs + ss*cs	; sheath admittance, 1/ohm.
ye = 1.0/re + ss*ce	; ESD admittance, 1/ohm.
yi = 1.0/ri + ss*ci	; op-amp input admittance, 1/ohm.

yc = 1.0/(rc+rl) + ss*cc	; cable+load admitance, 1/ohm.

zs = 1.0/ys
ze = 1.0/ye
zi = 1.0/yi
zc = 1.0/yc

gv1 = zi/(zs+ze+zi)	; follower output voltage gain, volt/volt.
gv2 = zc/(ro+zc)	; output and cable voltage gain, volt/volt.

gv_tot = gv1*gv2

if keyword_set(complex_response) then $
  resp = gv_tot $
else $
  resp = float( sqrt( gv_tot*conj( gv_tot)))

return
end
