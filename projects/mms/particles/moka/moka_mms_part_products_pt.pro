;+
;
;Procedure:
;  moka_mms_part_products_pt
;
;Purpose:
;  To generate pitch-angle vs time spectrograms from the distribution data
;  dumped into a tplot variable by
;    moka_mms_part_products,name,mag_name=mag_name,out=['pad']
;
;History:
;  Created on 2017-01-01 by moka
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-10-06 09:35:27 -0700 (Thu, 06 Oct 2016) $
;$LastChangedRevision: 22050 $
;$URL: svn+ssh://ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_part_products.pro $
;-
PRO moka_mms_part_products_pt,name,trange=tr,padding=padding,acc=acc,norm=norm,$
  ranges=ranges, suffix=suffix
  compile_opt idl2
  if undefined(padding) then padding=1
  if undefined(acc) then acc=0
  
  ;--------------------
  ; initialize
  ;--------------------
  sc = strmid(name,0,4)  
  get_data,name,data=D,dl=dl,lim=lim
  nmax = n_elements(D.x)
  wegy= D.V1 & imax = n_elements(wegy)
  wpa = D.V2 & jmax = n_elements(wpa)
  if undefined(tr) then begin
    tr = [D.x[0], D.x[nmax-1]]
  endif else begin
    tr = time_double(tr)
  endelse
  idx = where((tr[0] le D.x)and(D.x le tr[1]), cmax)
  dpa = wpa[1]-wpa[0]
  dt = D.x[1]-D.x[0]
  nacc = floor(double(acc)/dt) > 1
  if nacc gt 1 then nh = floor(0.5d0*double(acc)/dt)
  
  ;-----------------------------
  ; Define energy bins
  ;-----------------------------
  if undefined(ranges) then begin
    EVERY_ENERGY_STEP = 1
    kmax = imax
    deh = 0.5*(wegy[1]-wegy[0])
    er = fltarr(kmax,2)
    for k=0,kmax-1 do begin
      er[k,*] = [wegy[k]-deh,wegy[k]+deh]
    endfor
  endif else begin
    EVERY_ENERGY_STEP = 0
    sz = size(ranges,/dim)
    kmax=sz[0]
    er = ranges
  endelse
  erlbl = strarr(kmax)
  
  ;------------------------
  ; For each energy bin
  ;------------------------
  wpad = fltarr(nmax,jmax,kmax)
  for k=0,kmax-1 do begin
    
    ;-------------------------
    ; Select and store data
    ;-------------------------
    idx = where( (er[k,0] le wegy) and (wegy lt er[k,1]), ct ) & if ct eq 0 then stop
    for j=0,jmax-1 do begin; for each pitch angle
      for n=0,nmax-1 do begin; for each time stamp
        wpad[n,j,k] = total(D.y[n,idx,j])/ct
      endfor; for n
    endfor; for j
    
    ;-----------------
    ; Normalization
    ;-----------------
    if keyword_set(norm) then begin
      for n=0,nmax-1 do begin; for each time stamp
        peak = max(wpad[n,*,k],/nan); find the peak
        wpad[n,0:jmax-1,k] /= peak
      endfor
    endif
    
    ;-----------------
    ; Integrate
    ;-----------------
    if nacc gt 1 then begin
      wpadtmp = fltarr(nmax,jmax,kmax)
      for j=0,jmax-1 do begin
      for n=0,nmax-1 do begin
        nstart = max([0,n-nh])
        nstop  = min([nmax-1,n+nh])
        wpadtmp[n,j,k] = total(wpad[nstart:nstop,j,k])/float(nstop-nstart+1)
      endfor
      endfor
      wpad = wpadtmp
    endif
    
    ;--------------------------
    ; Padding for plot purpose
    ;--------------------------
    if keyword_set(padding) then begin
      wpadnew = fltarr(nmax,jmax+2,kmax)
      wpadnew[0:nmax-1,1:jmax, k] = wpad[0:nmax-1,0:jmax-1,k]
      wpadnew[0:nmax-1,     0, k] = wpadnew[0:nmax-1,   1, k]
      wpadnew[0:nmax-1,jmax+1, k] = wpadnew[0:nmax-1,jmax, k]
      wpad = wpadnew
      wpafinal = [wpa[0]-dpa,wpa,wpa[jmax-1]+dpa]
;      print,k,'padded'
;      stop
    endif else begin
      wpafinal=wpa
    endelse
    
    idx = where(wpad eq 0.,ct)
    if ct gt 0 then begin
      wpad[idx] = !VALUES.F_NAN
    endif
    ermin = er[k,0]
    ermax = er[k,1]
    eruni = 'eV'
    erctr = wegy[k]
    fmt = '(I5)'
    if (ermin ge 1000.) and (ermax ge 1000.) then begin
      ermin *= 0.001
      ermax *= 0.001
      erctr *= 0.001
      eruni = 'keV'
      fmt = '(F8.1)'
    endif
    
    
    sfx = (undefined(suffix)) ? '' : suffix
    if EVERY_ENERGY_STEP then begin
      cegy0 = strtrim(string(erctr,format=fmt),2)
      tnlbl = strtrim(string(cegy0,format=fmt),2)
      tn =sc+'_pad_'+cegy0+'_'+eruni+sfx 
    endif else begin
      cegy0 = strtrim(string(ermin,format=fmt),2)
      cegy1 = strtrim(string(ermax,format=fmt),2)
      tnlbl = cegy0+'-'+cegy1+' '+eruni+'!CPitch Angle'
      tn =sc+'_pad_'+cegy0+'-'+cegy1+'_'+eruni+sfx
    endelse
    
    store_data, tn,data={x:D.x,Y:reform(wpad[*,*,k]),V:wpafinal},dl=dl
    options, tn, ytitle=tnlbl,ytickinterval=45,constant=0

    ylim, tn, 0, 180, 0
    if keyword_Set(norm) then begin
      zlim, tn, 0, 1, 0
      options,tn,ztitle=' '
      options,tn,'normalize',1
    endif else begin
      options,tn,'zrange',/delete
      options,tn,'zlog',1
      options,tn,'normalize',0
    endelse
  endfor; for k

END
