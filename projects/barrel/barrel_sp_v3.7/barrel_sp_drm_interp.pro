;Modified 8/12/14 (version 3.5): switch to version 4 response matrix
;(_sphere_) and divide by 1.d8 for correct normalization.

;Modified 4/5/16 (version 3.7): switch to version 6 response matrix
;(_v6_)

function barrel_sp_drm_interp,altitude,ein,loginterpolate=loginterpolate,$
         pitch=pitch,show=show,verbose=verbose

v4=0

; loginterpolate = 1 : logarithmic interpolation

if not keyword_set(pitch) then pitch='iso'
if pitch NE 'iso' and pitch NE 'mir' then $
  message,"Illegal distribution name.  Use iso or mir."
if altitude LT 25. then begin
  print,"BARREL_SP_RESPONSE_INTERP Warning: altitude < 25 km, being set to 25 km."
  altitude = 25.
endif
if altitude GT 40. then begin
  print,"BARREL_SP_RESPONSE_INTERP Warning: altitude > 40 km, being set to 40 km."
  altitude = 40.
endif

if keyword_set(show) then  loadct,13

altstr=strtrim(floor(altitude),2)

; 27 electron energy input curve fitting parms a[0-5]
if v4 then $
 filename=barrel_find_file(pitch+'_sphere_'+altstr+'k_fit_parms','barrel_sp_v3.7')$
else $
 filename=barrel_find_file(pitch+'_v6c_'+altstr+'k_fit_parms','barrel_sp_v3.7')

n1=datin(filename,8,d)
es=reform(d[0,*])
if (ein lt es[0])||(ein gt 4000.) then begin
 if keyword_set(verbose) then   $
    print,"Electron energy out of range: "+strtrim(ein,2)+". Use " + strtrim(es[0],2)
    return,0
endif

; to find the nearest energy and for later interpolation
for i=0,n1-1 do begin
    if ((ein eq es[i])||(ein eq 4000)) then begin
	i1=i
	i2=i
	g1=0.
    endif else begin
	if ((ein GT es[i]) &&(ein LT  es[i+1])) then begin
	   i1=i
	   i2=i+1
	   g1= float((ein-es[i])/(es[i+1]-es[i]))
	endif
    endelse
 endfor

; here shift/stretch the energy scale so that 
; ebins range	[24,ein]
; e1 range 	[24,es[i1]]
; e2 range	[24,es[i2]]
; [0,23] is out of fitting range.

ebins = findgen(ein)*(ein-24.)/ein+24.
e1 = findgen(ein)*((es[i1]-24.)/ein)+24.
e2 = findgen(ein)*((es[i2]-24.)/ein)+24.

curve = fltarr(ein)
if (g1 eq 0.) then begin
    a=d[1:6,i1]
    barrel_sp_brem,ebins,a,f1

    ;Fix some blowing up at low energies temporarily:
    barrel_sp_patch_drmrow,f1

    curve = f1
    if keyword_set(show) then $
       plot,ebins,f1,/xlog,/ylog,color=150,xrange=[10,5000],$
            yrange=[0.0001,10000],$
            xtitle='X-Ray Energy (KeV)',ytitle='Xray Flux Cts/Kev'
endif else begin
    a=d[1:6,i1]
    barrel_sp_brem,e1,a,f1
    a=d[1:6,i2]
    barrel_sp_brem,e2,a,f2

    ;Fix some blowing up at low energies temporarily:
    barrel_sp_patch_drmrow,f1
    barrel_sp_patch_drmrow,f2

    if ( keyword_set(loginterpolate)) then begin
       curve = exp ( $
       (alog(f1)*(es[i2]-ein) + alog(f2)*(ein-es[i1]) )/(es[i2]-es[i1]))
    endif else begin      
       curve =   $
       (  f1*(es[i2]-ein) + f2*(ein-es[i1]) ) / (es[i2]-es[i1])
    endelse     
    if keyword_set(show) then begin
       plot,e1,f1,/xlog,/ylog,color=150,xrange=[10,10000],$
            yrange=[0.0001,10000],linestyle=3, $
            xtitle='X-Ray Energy (KeV)',$
            ytitle='Xray Flux Cts/Kev'
       oplot,e2,f2,color=80,linestyle=2
       oplot,ebins,curve
    endif
endelse

a=fltarr(2,ein)
a[0,*]=ebins
a[1,*]=curve

return,a

end
