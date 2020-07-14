;+
; NAME: rotate_field_2_vec.pro
; SYNTAX: rbsp_rotate_field_2_vec,'waveform','vec'
;			where 'waveform' is a tplot variable and 'vec'
;			is either a tplot variable or an array of [3]
;
; PURPOSE: Returns the input waveform or vector rotated to one of the following systems.
;				a) Min Var - input "vec" (e.g. DC Bfield) only
;					z-hat defined to be direction of "vec"
;					y_hat is given by vec cross x_max, where x_max is the maximum variance eigenvector
;					x_hat - max variance eigenvector always lies in x-z plane
;					Uses this system by default unless /efa is set or "vec2" is input
;				b) Two vec - input "vec" and "vec2"
;					z-hat is direction of "vec"
;					y-hat = (vec x vec2)/|vec2 x vec|
;					x-hat = (y-hat x vec)/|vec x y-hat|  (vec2 is in x-z plane)
;					Uses this if "vec2" is set
;         ***Can be used to define a radial, azimuthal, Bo coord system with
;           vec = Bo
;           vec2 = r  (radial direction)
;         So,  z-hat ~ Bo
;              y-hat ~ (Bo x r)        (azimuthal)
;              x-hat ~ (y-hat x Bo)    (radial)
;
;				c) EFA - similar to Two Vec, but doesn't require an additional input vector
;					z-hat is direction of "vec"
;					y-hat is the x-axis of input coord (roughly), formed by crossing vec
;					with [0,1,0].
;					Uses this if /efa is set
;
; INPUT: Tplot variable names of:
;       waveform -> Name of tplot variable of [m,3] or [3] waveform data. Note that if the
;					Min var rotation is requested then must input a [m,3] where m>1
;	vec   -> [3] element vector OR name of tplot variable
;	         containing [n,3] element vector to represent the z-hat direction. Ex.
;					Bo in the coord system of "waveform".
;					Note that the coordinates of
;					"vec" and "waveform" must be
;					the same!
;                                       Also note that m != n necessarily
;		vec2  -> (optional) Same type as "vec". Used to determine the perp
;					direction ("Two vec" rotation only). The x-z plane will contain vec2.
;					Note that vec2 must be the same size as vec
;
;
; Other keywords:
;     vec2_rotated --> vec2 projected along the new coordinate system
;
;
; NOTES: For EFA and Two Vec rotations, if "waveform" and "vec" have the same number of elements then
;		the rotations are vectorized and the program runs quickly. This doesn't work for the Min Var
;		rotation b/c "waveform" and "vec" cannot be the same size.
;
; OUTPUT: Returns tplot variables of rotated waveform in requested coordinates
;
; HISTORY:
; 	CREATED BY:    Aaron Breneman, 03/16/2010
;				   Major modification for use with tplot variables AWB (2/26/2014)
;
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2020-07-13 16:24:22 -0700 (Mon, 13 Jul 2020) $
;   $LastChangedRevision: 28885 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/utils/rbsp_rotate_field_2_vec.pro $
;-




function rbsp_rotate_field_2_vec,waveform,vec,vec2=vec2,efa=efa,$
  vecrotated=vec2_rotated


  get_data,waveform,data=wf

  if ~is_struct(wf) then begin
     print,'NO WAVEFORM DATA INPUTTED. CANNOT ROTATE'
     return,1
  endif else begin
     ndim = size(wf.y,/n_dimensions)
     sz = size(wf.y)
  endelse



  tst = size(vec,/structure)
  if tst.type_name eq 'STRING' then get_data,vec,data=vec_tmp
  if (tst.type_name eq 'FLOAT') or (tst.type_name eq 'INT') or (tst.type_name eq 'DOUBLE') then begin
     timetmp = wf.x[0]
     vec_tmp = {x:[timetmp,timetmp],y:[[vec[0],vec[0]],[vec[1],vec[1]],[vec[2],vec[2]]]}
  endif


  tst = size(vec2,/structure)
  if tst.type_name ne 'UNDEFINED' then begin
     if tst.type_name eq 'STRING' then get_data,vec2,data=vec2_tmp
     if (tst.type_name eq 'FLOAT') or (tst.type_name eq 'INT') or (tst.type_name eq 'DOUBLE') then begin
        timetmp = wf.x[0]
        vec2_tmp = {x:[timetmp,timetmp],y:[[vec2[0],vec2[0]],[vec2[1],vec2[1]],[vec2[2],vec2[2]]]}
     endif
  endif


  if is_struct(vec_tmp)  then vecgoo = vec_tmp
  if is_struct(vec2_tmp) then vec2goo = vec2_tmp





;-----------------------------------------------------------------------------
;Basic error handling
;-----------------------------------------------------------------------------


  if is_struct(vecgoo) and is_struct(vec2goo) then begin
     s1 = size(vecgoo.y)
     s2 = size(vec2goo.y)
     if not (s1[1] eq s2[1]) or not (s1[2] eq s2[2]) then begin
        print,'VEC AND VEC2 MUST HAVE THE SAME SIZE'
        return,1
     endif
  endif


  if ~is_struct(vecgoo) then begin
     print,'NO VECTOR (TO ROTATE TO) INPUTTED. CANNOT ROTATE'
     return,1
  endif


  if (ndim eq 0) or (ndim gt 2) then begin
     print,'DIMENSIONS OF WAVEFORM NOT CORRECT....RETURNING'
     return,1
  endif


  ;If waveform is a 2D array, make sure it is an [n,3] array, where n>1
  ;It needs to have more than one element in the first dimension to complete the MV analysis

  if ndim eq 2 then begin

                                ;First, make sure second dimension is size 3
     if sz[2] ne 3 then begin
        print,'NOT AN [n,3] ARRAY NECESSARY FOR MV ANALYSIS'
        return,1
     endif

                                ;If running MV analysis, make sure that n>1
     if (sz[1] lt 2) and (~keyword_set(vec2)) and (~keyword_set(efa)) then begin
        print,'n MUST BE > 1 IN THE [n,3] ARRAY FOR THE MV ANALYSIS'
        return,1
     endif

                                ;If not running MV analysis, and the first dimension is 1, then reform the array
     if keyword_set(vec2) or keyword_set(efa) then begin
        if (sz[1] eq 1) then waveform = reform(waveform)
     endif
  endif
                                ;--------------

                                ;If waveform is a 1D array, make sure that it is of size [3] and that a MV analysis
                                ;is not being requested.

  if ndim eq 1 then begin

                                ;Make sure we're not requesting MV analysis
     if (~keyword_set(vec2)) and (~keyword_set(efa)) then begin
        print,'INCORRECT SIZE ON INPUT WAVEFORM VECTOR FOR USING MV ROTATION OPTION'
        print,'WAVEFORM MUST BE [n,3] WHERE n>1'
        return,1
     endif

                                ;Now, make sure second dimension is size 3
     if sz[1] ne 3 then begin
        print,'WAVEFORM IS NOT A SIZE [3] ARRAY'
        return,1
     endif

                                ;change to a [1,3] array
     waveform = reform(waveform,1,3)

  endif
                                ;-------------




  boo = size(vecgoo.y,/dimensions)
  if n_elements(boo) gt 1 then Vecmag = sqrt(vecgoo.y[*,0]^2 + vecgoo.y[*,1]^2 + vecgoo.y[*,2]^2)
  if n_elements(boo) eq 1 then Vecmag = sqrt(vecgoo.y[0]^2 + vecgoo.y[1]^2 + vecgoo.y[2]^2)
  if is_struct(vec2goo) then begin
     boo = size(vec2goo.y,/dimensions)
     if n_elements(boo) gt 1 then Vec2mag = sqrt(vec2goo.y[*,0]^2 + vec2goo.y[*,1]^2 + vec2goo.y[*,2]^2)
     if n_elements(boo) eq 1 then Vec2mag = sqrt(vec2goo.y[0]^2 + vec2goo.y[1]^2 + vec2goo.y[2]^2)
  endif

  x=[1,0,0]
  y=[0,1,0]
  z=[0,0,1]




  ;-------------------------------------------------------------------------------------------
  ;DETERMINE NUMBER OF CHUNKS. ALL THE DATA WITHIN A CHUNK IS ROTATED TO A SINGLE VECTOR "VEC"
  ;-------------------------------------------------------------------------------------------

  nchunks = n_elements(vecgoo.x)
  chsz = n_elements(wf.x)/(nchunks-1) ;size of each chunk

;  ;number of additional times to loop to compensate for rounding error
;  ;when calculating chsz
;  remainder = (n_elements(wf.x) - nchunks*chsz)/chsz


  ;The size of each chunk must be greater than 1 for a min variance analysis
  if chsz le 1 and ~keyword_set(vec2) and ~keyword_set(efa) then begin
     print,'CHUNK SIZE (CHSZ) MUST BE > 1 FOR MIN VAR ANALYSIS'
     print,'MAKE SURE THAT THE VECTOR YOU ARE ROTATING TO DOESNT HAVE THE SAME # OF DATA POINTS AS WAVEFORM'
     return,1
  endif

                                ;remainder
  print,'REMAINDER = ',chsz*nchunks mod n_elements(wf.x)

  vecFAx = fltarr(n_elements(wf.x))
  vecFAy = fltarr(n_elements(wf.x))
  vecFAz = fltarr(n_elements(wf.x))



  ;--------------------------------
  ;ROTATE TO MIN VAR COORD.....
  ;--------------------------------
  if ~keyword_set(efa) and ~keyword_set(vec2) then begin

     ;Check for NaN values. These will mess up Minvar rotation
     goo = where(finite(wf.y) eq 0)
     too = where(finite(wf.x) eq 0)
     if goo[0] ne -1 or too[0] ne -1 then begin
        print,'NaN VALUES IN WAVEFORM OR TIME ARRAY. CANT PERFORM MINVARIANCE ANALYSIS FOR ALL CHUNKS'
        print,'...THEREFORE THERE WILL BE GAPS IN END PRODUCT';
;        return,1
     endif


     Emax = fltarr(n_elements(vecgoo.x),3)
     Eint = fltarr(n_elements(vecgoo.x),3)
     Emin = fltarr(n_elements(vecgoo.x),3)
     khat = fltarr(n_elements(vecgoo.x),3)
     theta_kb = fltarr(n_elements(vecgoo.x))
     dtheta_kb = fltarr(n_elements(vecgoo.x))



     for j=0L,nchunks-2 do begin

        s = j*chsz
        e = (j+1)*chsz-1

        ;Test for NaN values in current chunk
        goo = where(finite(wf.y[s:e,*]) eq 0)
        too = where(finite(wf.x[s:e,*]) eq 0)

;        if goo[0] ne -1 or too[0] ne -1 then stop

        if goo[0] eq -1 and too[0] eq -1 then begin

        ;find minimum variance field components
        vals = rbsp_min_var_rot(wf.y[s:e,*],bkg_field=reform(vecgoo.y[j,*]),/nomssg)
        Emaxt = vals.eigenvectors[*,2]*vals.eigenvalues[0]
        Eintt = vals.eigenvectors[*,1]*vals.eigenvalues[1]
        Emint = vals.eigenvectors[*,0]*vals.eigenvalues[2]


        Emax_mag = sqrt(total(Emaxt^2))
        Eint_mag = sqrt(total(Eintt^2))
        Emin_mag = sqrt(total(Emint^2))
        Emax_hat = Emaxt/Emax_mag


        zs = reform(vecgoo.y[j,*]/Vecmag[j])
        ys = crossp(zs,Emax_hat)
        ysmag = sqrt(ys[0]^2 + ys[1]^2 + ys[2]^2)
        ys = ys/ysmag
        xs = crossp(ys,zs)
        xsmag = sqrt(xs[0]^2 + xs[1]^2 + xs[2]^2)
        xs = xs/xsmag


                                ;Test angles
                                ;print,acos(total(xs*zs))/!dtor
                                ;print,acos(total(ys*zs))/!dtor
                                ;print,acos(total(xs*ys))/!dtor


        ;redefine vectors in Min Var coord -----------
        vec_minvar = [0,0,Vecmag[j]]


        Emax[j,*] = [total(Emaxt*xs),total(Emaxt*ys),total(Emaxt*zs)]
        Eint[j,*] = [total(Eintt*xs),total(Eintt*ys),total(Eintt*zs)]
        Emin[j,*] = [total(Emint*xs),total(Emint*ys),total(Emint*zs)]
        khat[j,*] = vals.k_hat
        theta_kb[j,*] = vals.theta_kb
        dtheta_kb[j,*] = vals.dtheta

        tmpx = wf.y[s:e,0]*xs[0] + wf.y[s:e,1]*xs[1] + wf.y[s:e,2]*xs[2]
        tmpy = wf.y[s:e,0]*ys[0] + wf.y[s:e,1]*ys[1] + wf.y[s:e,2]*ys[2]
        tmpz = wf.y[s:e,0]*zs[0] + wf.y[s:e,1]*zs[1] + wf.y[s:e,2]*zs[2]

        vecFAx[s:e] = tmpx
        vecFAy[s:e] = tmpy
        vecFAz[s:e] = tmpz

      endif  ;NaN check

     endfor

     Emax_mag = sqrt(Emax[*,0]^2 + Emax[*,1]^2 + Emax[*,2]^2)
     Eint_mag = sqrt(Eint[*,0]^2 + Eint[*,1]^2 + Eint[*,2]^2)
     Emin_mag = sqrt(Emin[*,0]^2 + Emin[*,1]^2 + Emin[*,2]^2)

                                ;print,'SIZE OF ORIGINAL ARRAY',size(wf.x)
                                ;print,'SIZE OF FINAL ARRAY',size(vecFAx)

     store_data,waveform + '_FA_minvar',data={x:wf.x,y:[[vecFAx],[vecFAy],[vecFAz]]}
     store_data,'emax_vec_minvar',data={x:vecgoo.x,y:Emax}
     store_data,'eint_vec_minvar',data={x:vecgoo.x,y:Eint}
     store_data,'emin_vec_minvar',data={x:vecgoo.x,y:Emin}
     store_data,'minvar_eigenvalues',data={x:vecgoo.x,y:[[Emax_mag],[Eint_mag],[Emin_mag]]}
     store_data,'emax2eint',data={x:vecgoo.x,y:Emax_mag/Eint_mag}
     store_data,'eint2emin',data={x:vecgoo.x,y:Eint_mag/Emin_mag}
     store_data,'theta_kb',data={x:vecgoo.x,y:theta_kb}
     store_data,'dtheta_kb',data={x:vecgoo.x,y:dtheta_kb}
     store_data,'emax_unitvec',data={x:vecgoo.x,y:Emax/Emax_mag}  ;defined in terms of input coord
     store_data,'eint_unitvec',data={x:vecgoo.x,y:Eint/Eint_mag}
     store_data,'emin_unitvec',data={x:vecgoo.x,y:Emin/Emin_mag}
     store_data,'k_unitvec',data={x:vecgoo.x,y:khat}

     struct = {notes:['ROTATED TO MIN-VAR COORDINATES']}


     return,struct
  endif



  ;------------------------------------------------------------------
  ;Two vector rotation (z-axis along vec and vec2 is in x-z plane)
  ;------------------------------------------------------------------
  if not keyword_set(efa) and keyword_set(vec2) then begin

     ;this will be the vec2 projected along the final coordinates.
     vec2_rotated = fltarr(nchunks,3)
     if chsz gt 1 then begin


        for j=0L,nchunks-2 do begin

           s = j*chsz
           e = (j+1)*chsz-1


           zs = reform(vecgoo.y[j,*]/Vecmag[j]) ;unit vector along z (mag field)
           ys = reform(crossp(zs,vec2goo.y[j,*]/Vec2mag[j]))
           ys = ys/sqrt(ys[0]^2 + ys[1]^2 + ys[2]^2)
           xs = crossp(ys,zs)
           xs = xs/sqrt(xs[0]^2 + xs[1]^2 + xs[2]^2)

                                ;Test angles
                                ;print,acos(total(xs*zs))/!dtor
                                ;print,acos(total(ys*zs))/!dtor
                                ;print,acos(total(xs*ys))/!dtor


           tmpx = wf.y[s:e,0]*xs[0] + wf.y[s:e,1]*xs[1] + wf.y[s:e,2]*xs[2]
           tmpy = wf.y[s:e,0]*ys[0] + wf.y[s:e,1]*ys[1] + wf.y[s:e,2]*ys[2]
           tmpz = wf.y[s:e,0]*zs[0] + wf.y[s:e,1]*zs[1] + wf.y[s:e,2]*zs[2]

           vecFAx[s:e] = tmpx
           vecFAy[s:e] = tmpy
           vecFAz[s:e] = tmpz

           vec2x = vec2goo.y[j,0]*xs[0] + vec2goo.y[j,1]*xs[1] + vec2goo.y[j,2]*xs[2]
           vec2y = vec2goo.y[j,0]*ys[0] + vec2goo.y[j,1]*ys[1] + vec2goo.y[j,2]*ys[2]
           vec2z = vec2goo.y[j,0]*zs[0] + vec2goo.y[j,1]*zs[1] + vec2goo.y[j,2]*zs[2]
           vec2_rotated[j,*] = [[vec2x],[vec2y],[vec2z]]/sqrt(vec2x^2 + vec2y^2 + vec2z^2)


        endfor
     endif

    ;if "vec" has the same number of elements as "wf" then we can do the rotations
    ;all at once
     if chsz eq 1 then begin

        n = n_elements(wf.x)
        x = fltarr(n,3)
        x[*,0] = 1
        y = fltarr(n,3)
        y[*,1] = 1
        z = fltarr(n,3)
        z[*,2] = 1


        zs = [[reform(vecgoo.y[*,0])/vecmag],[reform(vecgoo.y[*,1])/vecmag],[reform(vecgoo.y[*,2])/vecmag]] ;unit vector along z (mag field)
        ys = [[zs[*,1]*vec2goo.y[*,2]-zs[*,2]*vec2goo.y[*,1]],[zs[*,2]*vec2goo.y[*,0]-zs[*,0]*vec2goo.y[*,2]],[zs[*,0]*vec2goo.y[*,1]-zs[*,1]*vec2goo.y[*,0]]]

        ysmag = sqrt(ys[*,0]^2 + ys[*,1]^2 + ys[*,2]^2)
        ys = [[ys[*,0]/ysmag],[ys[*,1]/ysmag],[ys[*,2]/ysmag]]
        xs = [[ys[*,1]*zs[*,2]-ys[*,2]*zs[*,1]],[ys[*,2]*zs[*,0]-ys[*,0]*zs[*,2]],[ys[*,0]*zs[*,1]-ys[*,1]*zs[*,0]]]
        xsmag = sqrt(xs[*,0]^2 + xs[*,1]^2 + xs[*,2]^2)
        xs = [[xs[*,0]/xsmag],[xs[*,1]/xsmag],[xs[*,2]/xsmag]]

        vecFAx = wf.y[*,0]*xs[*,0] + wf.y[*,1]*xs[*,1] + wf.y[*,2]*xs[*,2]
        vecFAy = wf.y[*,0]*ys[*,0] + wf.y[*,1]*ys[*,1] + wf.y[*,2]*ys[*,2]
        vecFAz = wf.y[*,0]*zs[*,0] + wf.y[*,1]*zs[*,1] + wf.y[*,2]*zs[*,2]

                                ;Test angles
                                ;print,acos(total(xs[1000,*]*zs[1000,*]))/!dtor
                                ;print,acos(total(ys[1000,*]*zs[1000,*]))/!dtor
                                ;print,acos(total(xs[1000,*]*ys[1000,*]))/!dtor


     endif



     store_data,waveform + '_twovec',data={x:wf.x,y:[[vecFAx],[vecFAy],[vecFAz]]}

     struct = {notes:['ROTATED TO SYSTEM DEFINED BY VEC1 (PARALLEL DIRECTION) AND VEC2 (PERP DIRECTION)']}
     return,struct

  endif

                                ;----------------------
                                ;EFA rotation
                                ;----------------------
  if keyword_set(efa) then begin

     if chsz gt 1 then begin
        for j=0L,nchunks-2 do begin

           s = j*chsz
           e = (j+1)*chsz-1

           zs = reform(vecgoo.y[j,*]/Vecmag[j])      ;unit vector along z (mag field)
           ys = crossp(zs,z)                      ;This y-axis will be relatively close to the original x-axis.
           ysmag = sqrt(ys[0]^2 + ys[1]^2 + ys[2]^2)
           ys = ys/ysmag
           xs = crossp(ys,zs)   ;This x-axis will roughly correspond to the original y-axis.
           xsmag = sqrt(xs[0]^2 + xs[1]^2 + xs[2]^2)
           xs = xs/xsmag


           tmpx = wf.y[s:e,0]*xs[0] + wf.y[s:e,1]*xs[1] + wf.y[s:e,2]*xs[2]
           tmpy = wf.y[s:e,0]*ys[0] + wf.y[s:e,1]*ys[1] + wf.y[s:e,2]*ys[2]
           tmpz = wf.y[s:e,0]*zs[0] + wf.y[s:e,1]*zs[1] + wf.y[s:e,2]*zs[2]

           vecFAx[s:e] = tmpx
           vecFAy[s:e] = tmpy
           vecFAz[s:e] = tmpz

        endfor
     endif

                                ;if "vec" has the same number of elements as "wf" then we can do the rotations
                                ;all at once
     if chsz eq 1 then begin

        n = n_elements(wf.x)
        x = fltarr(n,3)
        x[*,0] = 1
        y = fltarr(n,3)
        y[*,1] = 1
        z = fltarr(n,3)
        z[*,2] = 1


        zs = [[reform(vecgoo.y[*,0])/vecmag],[reform(vecgoo.y[*,1])/vecmag],[reform(vecgoo.y[*,2])/vecmag]] ;unit vector along z (mag field)
        ys = [[zs[*,1]*z[*,2]-zs[*,2]*z[*,1]],[zs[*,2]*z[*,0]-zs[*,0]*z[*,2]],[zs[*,0]*z[*,1]-zs[*,1]*z[*,0]]]
        ysmag = sqrt(ys[*,0]^2 + ys[*,1]^2 + ys[*,2]^2)
        ys = [[ys[*,0]/ysmag],[ys[*,1]/ysmag],[ys[*,2]/ysmag]]
        xs = [[ys[*,1]*zs[*,2]-ys[*,2]*zs[*,1]],[ys[*,2]*zs[*,0]-ys[*,0]*zs[*,2]],[ys[*,0]*zs[*,1]-ys[*,1]*zs[*,0]]]
        xsmag = sqrt(xs[*,0]^2 + xs[*,1]^2 + xs[*,2]^2)
        xs = [[xs[*,0]/xsmag],[xs[*,1]/xsmag],[xs[*,2]/xsmag]]

        vecFAx = wf.y[*,0]*xs[*,0] + wf.y[*,1]*xs[*,1] + wf.y[*,2]*xs[*,2]
        vecFAy = wf.y[*,0]*ys[*,0] + wf.y[*,1]*ys[*,1] + wf.y[*,2]*ys[*,2]
        vecFAz = wf.y[*,0]*zs[*,0] + wf.y[*,1]*zs[*,1] + wf.y[*,2]*zs[*,2]

     endif



                                ;print,'SIZE OF FINAL ARRAY',size(vecFAx)
                                ;print,'SIZE OF ORIGINAL ARRAY',size(wf.x)
     store_data,waveform + '_EFA_coord',data={x:wf.x,y:[[vecFAx],[vecFAy],[vecFAz]]}

     struct = {notes:['ROTATED TO EFA COORDINATES']}
     return,struct



  endif
end
