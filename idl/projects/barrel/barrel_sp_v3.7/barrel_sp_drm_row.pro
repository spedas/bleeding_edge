function barrel_sp_drm_row, altitude, ein, ctbins, show=show, pitch=pitch

if not keyword_set(pitch) then pitch='iso'
if pitch NE 'iso' and pitch NE 'mir' then $
  message,"Illegal distribution name.  Use iso or mir."
if altitude LT 25. then begin
  print,"BARREL_SP_RESPONSE_INTERP Warning: "+$
           "altitude < 25 km, being set to 25 km."
  altitude = 25.
endif
if altitude GT 40. then begin
  print,"BARREL_SP_RESPONSE_INTERP Warning: "+$
          "altitude > 40 km, being set to 40 km."
  altitude = 40.
endif
al=[25.,30.,35.,40.]

if ein LT 50. or ein GT 4000. then return, fltarr(n_elements(ctbins)-1)

for i=0,2 do begin
      if ((altitude eq al[i])||(altitude eq 40)) then begin
	 sp = barrel_sp_drm_interp(altitude,ein,/loginterpolate,pitch=pitch)
         if (n_elements(sp) eq 1) then message,"Energy out of range."
      endif else begin
	 if ((altitude gt al[i])&&(altitude lt al[i+1])) then begin
	    sp1=barrel_sp_drm_interp(al[i],ein,/loginterpolate,pitch=pitch)
	    sp2=barrel_sp_drm_interp(al[i+1],ein,/loginterpolate,pitch=pitch)
	    n1=n_elements(sp1)
	    n2=n_elements(sp2)
            if (n_elements(sp1) eq 1) then message,"Energy out of range."
	    de=sp2[0,*]-sp1[0,*]
	    ga = (altitude - al[i])/5.
	    sp=fltarr(2,n_elements(sp2[1,*]))
	    sp[0,*]=sp2[0,*]
	    sp[1,*] = sp1[1,*]+ga*(sp2[1,*]-sp1[1,*])

            if keyword_set(show) then begin
               plot,sp1[0,*],sp1[1,*],/xlog,/ylog,xrange=[10,10000],$
                    yrange=[0.01,10000],psym=5,symsize=0.5,$
                    xtitle='X-Ray Energy (KeV)',ytitle='Xray Flux Cts/Kev',$
                    title='Altitude: '+strtrim(altitude,2)+' km; Energy: '+strtrim(ein,2)+' keV'
               oplot,sp2[0,*],sp2[1,*],psym=4,symsize=0.4		
               oplot,sp[0,*],sp[1,*]
            endif
	 endif
      endelse
  endfor

;rebin to desired energy bins:

e1 = [reform(sp[0,*])-0.5,sp[0,n_elements(sp[0,*])-1]+1.0]
s1 = reform(sp[1,*])
e2 = ctbins
row=brl_rebin(s1,e1,e2,flux=1)

return,row

end
