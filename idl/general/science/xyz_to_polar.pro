;+
;PROCEDURE:  xyz_to_polar,xyz
;PURPOSE: Calculates magnitude, theta and phi given a 3 vector
;INPUT:   several options exist for xyz:
;    string:    data associated with the string is used.
;    structure: data.y is assumed to contain the xyz array
;    array(n,3)   n by (x,y,z components)
;    array(3)      vector:  [x,y,z]
;RETURN VALUES: through the keywords.  Same dimensions and type as the
;    input value of x.
;KEYWORDS:    Named variables in which results are put
;   MAGNITUDE:
;   THETA:
;   PHI:
;   MAX_VALUE:
;   MIN_VALUE:
;   MISSING:
;OPTION KEYWORDS:  These are used to set "cart_to_sphere" opts.
;   CO_LATITUDE:   If set theta will be in co-latitude. (0<=theta<=180)
;   PH_0_360:      If set positive, 0<=phi<=360, if zero, -180<=phi<=180.
;                  If set negative, will guess the best phi range.
;   PH_HIST:       A 2 element vector, a min and max histeresis value.
;   
;SEE ALSO:
;  sphere_to_cart.pro
;   
;EXAMPLES:
;
;     Passing arrays:
;x = findgen(100)
;y = 2*x
;z = x-20
;vecs = [[x],[y],[z]]
;xyz_to_polar,vecs,mag=mag      ;mag will be the magnitude of the array.
;
;     Passing a structure:
;dat = {ytitle:'Vector',x:findgen(100),y:vecs}
;xyz_to_polar,dat,mag=mag,theta=th,phi=ph
;mag,th and ph will be all be structures.
;
;     Passing a string:  (see store_data, get_data)
;xyz_to_polar,'Vp'   ; This assumes data has been created for this string.
;    This will compute new data quantities: 'Vp_mag','Vp_th','Vp_ph'
;-

pro xyz_to_polar,data, $
    magnitude = magnitude, $
    theta = theta, $
    phi = phi,  $
    quick_mag=quick_mag,  $
    tagname = tagname,  $
    max_value=max_value, $
    min_value=min_value, $
    missing = missing, $
    clock = clock, $
    co_latitude=co_latitude,$
    tplotnames=tplotnames, $
    ph_0_360=ph_0_360, $
    negate = negate,  $
    ph_hist=ph_hist

switch size(/type,data) of
   2:           ; integers
   3:
   7: begin     ; strings
      names = tnames(data,n)
      tplotnames=''
      for i=0,n-1 do begin
        dprint,dlevel=3 ,'Computing polar coordinates for ',names[i]
        get_data,names[i],data=struct    ;,limits=lim
        str_element,struct,'max_value',val=max_value
        str_element,struct,'min_value',val=min_value
        if size(/type,struct) ne 8 then return       ; error
        xyz_to_polar,struct,mag=mag_struct,theta=th_struct,phi=ph_struct, $
            tagname= tagname,clock=clock,  $
            max_value=max_value,min_value=min_value,$
            co_latitude=co_latitude,ph_0_360=ph_0_360,ph_hist=ph_hist,negate=negate
        magnitude = names[i]+'_mag'
        theta     = names[i]+ (keyword_set(clock) ? '_con' : '_th')
        phi       = names[i]+ (keyword_set(clock) ? '_clk' : '_phi')
        store_data,magnitude,data=mag_struct
        tn = [magnitude]
        if ~keyword_set(quick_mag) then begin
          store_data,theta    ,data=th_struct
          store_data,phi      ,data=ph_struct,dlim={ynozero:1}
          tn = [magnitude,theta,phi]
        endif
        tplotnames = keyword_set(tplotnames) ? [tplotnames,tn] : tn
      endfor
      return
      end
   8: begin                                       ; structures
      if keyword_set(tagname) then begin
         str_element,data,tagname,value=v
         v = transpose(v)
      endif  else v = data.y
      xyz_to_polar,v,mag=mag_val,theta=theta_val,phi=phi_val,$
         max_value=max_value,min_value=min_value,missing=missing,$
          co_latitude=co_latitude,ph_0_360=ph_0_360,ph_hist=ph_hist,clock=clock,negate=negate
      if keyword_set(tagname) then begin
;stop
         str_element,/add,data,tagname+'_mag',mag_val
         str_element,/add,data,tagname+'_th',theta_val
         str_element,/add,data,tagname+'_phi',phi_val
      endif else begin
;         yt = ''
         str_element,data,'ytitle',val=yt
         magnitude = {x:data.x, y:mag_val}
         theta     = {x:data.x, y:theta_val}
         phi       = {x:data.x, y:phi_val}
;         if keyword_set(yt) then begin
;            str_element,/add,magnitude,'ytitle',yt+' (mag)'
;            str_element,/add,theta,'ytitle',yt+' (theta)'
;            str_element,/add,phi,'ytitle',yt+' (phi)'
;         endif
;         if keyword_set(min_value) then begin
;            str_element,/add,magnitude,'min_value',min_value
;            str_element,/add,theta,'min_value',min_value
;            str_element,/add,phi,'min_value',min_value
;         endif
;         if keyword_set(max_value) then begin
;            str_element,/add,magnitude,'max_value',max_value
;            str_element,/add,theta,'max_value',max_value
;            str_element,/add,phi,'max_value',max_value
;         endif
      endelse
      return
      end
   else: begin                                    ; normal arrays
      if ndimen(data) eq 2 then begin
         x = data[*,0]
         y = data[*,1]
         z = data[*,2]
      endif else begin
         x = data[0]
         y = data[1]
         z = data[2]
      endelse
      if keyword_set(negate) then begin
        x = -x
        y = -y
        z = -z
      endif
      if keyword_set(clock) then $
      cart_to_sphere,z,-y,x,magnitude,theta,phi,$
         co_latitude=co_latitude,ph_0_360=ph_0_360,ph_hist=ph_hist $
      else $
      cart_to_sphere,x,y,z,magnitude,theta,phi,$
         co_latitude=co_latitude,ph_0_360=ph_0_360,ph_hist=ph_hist
      if keyword_set(max_value) then begin
         ind = where(x ge max_value,count)
         if count gt 0 then begin
            if n_elements(missing) eq 0 then missing = max(x)
            magnitude[ind]=missing
            theta[ind]=missing
            phi[ind]=missing
         endif
      endif
      if keyword_set(min_value) then begin
         ind = where(x le min_value,count)
         if count gt 0 then begin
            if n_elements(missing) eq 0 then missing = min(x)
            magnitude[ind]=missing
            theta[ind]=missing
            phi[ind]=missing
         endif
      endif
      return
      end
endswitch

end








