;+
; PROCEDURE:
;       kgy_calc_bcon
; PURPOSE:
;       Calculates B connection between s/c and the Moon
; CALLING SEQUENCE:
;       kgy_calc_bcon, tvar_Rme = 'kgy_lmag_Rme', tvar_Bme = 'kgy_lmag_Bme'
; KEYWORDS:
;       tvar_Rme: tplot variable of s/c position in ME coordinates
;       tvar_Bme: tplot variable of B vector in ME coordinates
; Output tplot variables:
;       'kgy_lmag_Bcon_flg' = Magnetic connection flag:
;                             0 (black) for no connection,
;                             1 (green) for anti-para connection (-B ==> Moon),
;                             2 (red) for parallel connection (+B ==> Moon)
;       'kgy_lmag_bimpact' = distant along the field line from s/c to footpoint
;       'kgy_lmag_fp_lat' = footpoint latitude in ME coordinates
;       'kgy_lmag_fp_lon' = footpoint longitude in ME coordinates
;       'kgy_lmag_belev' = B elevation angle from the surface at the footpoint
;       'kgy_lmag_surfloc' = footpoint location (normalized by rL)
; CREATED BY:
;       Yuki Harada
;       - modified from 'art_bconnect_bres.pro' written by Andrew Poppe
;       - tvar_Rme and tvar_Bme should have the same time array
;         (time interpolation not included)
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2016-09-18 17:19:45 -0700 (Sun, 18 Sep 2016) $
; $LastChangedRevision: 21853 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/lmag/kgy_calc_bcon.pro $
;-

pro kgy_calc_bcon, tvar_Rme=tvar_Rme, tvar_Bme=tvar_Bme, verbose=verbose, suffix=suffix

if ~keyword_set(suffix) then suffix = ''
if ~keyword_set(tvar_Rme) then tvar_Rme = 'kgy_lmag_Rme'
if ~keyword_set(tvar_Bme) then tvar_Bme = 'kgy_lmag_Bme'

rL = 1737.4                     ;- km

;----- calc Bcon -----------------------------------------
get_data,tvar_Rme,data=dRme
get_data,tvar_Bme,data=dBme

Bcon_flg = intarr(n_elements(dRme.x),2)
surfloc = fltarr(n_elements(dRme.x),3)
bimpact = fltarr(n_elements(dRme.x))
belev = fltarr(n_elements(dRme.x))

dprint,dlevel=1,verbose=verbose,'calc Bcon start'
for i_t=0ll,n_elements(dRme.x)-1 do begin ;- time loop
   xt = fltarr(2000) & yt = fltarr(2000) & zt = fltarr(2000)

   bhat = [ dBme.y[i_t,0] , dBme.y[i_t,1] , dBme.y[i_t,2] ] $
          /sqrt( dBme.y[i_t,0]^2+dBme.y[i_t,1]^2+dBme.y[i_t,2]^2 )
   t = findgen(2000) * 1e-2 - 10. ;- search from -10 to 10 rL
   xt = dRme.y[i_t,0]/rL + bhat[0]*t
   yt = dRme.y[i_t,1]/rL + bhat[1]*t
   zt = dRme.y[i_t,2]/rL + bhat[2]*t

   dist = sqrt( xt^2 + yt^2 + zt^2 )

   if min(dist,i_min) le 1. then begin
      if i_min lt 1000 then Bcon_flg[i_t,*] = 1 ;- anti-para connection
      if i_min ge 1000 then Bcon_flg[i_t,*] = 2 ;- parallel connection

      ;- determine location on lunar surface
      surfdist = dist - 1.
      idx_surf = where( surfdist lt 0. , idx_surf_cnt )
      idx_end = [ idx_surf[0] , idx_surf[idx_surf_cnt-1] ]
      if i_min lt 1000 then idx_end = idx_end[1] else idx_end = idx_end[0]
      idx_end = idx_end + indgen(3) - 1
      surfloc[i_t,0] = interpol( xt[idx_end], surfdist[idx_end] , 0. )
      surfloc[i_t,1] = interpol( yt[idx_end], surfdist[idx_end] , 0. )
      surfloc[i_t,2] = interpol( zt[idx_end], surfdist[idx_end] , 0. )

      ;- calculate the distance from s/c to Moon along field line
      bimpact[i_t] = sqrt( (dRme.y[i_t,0]/rL - surfloc[i_t,0])^2 + $
                           (dRme.y[i_t,1]/rL - surfloc[i_t,1])^2 + $
                           (dRme.y[i_t,2]/rL - surfloc[i_t,2])^2 )

      ;- calculate the elevation angle of B at the foot point
      belev[i_t] = (!dpi/2. - acos( bhat[0]*surfloc[i_t,0] $
                                    + bhat[1]*surfloc[i_t,1] $
                                    + bhat[2]*surfloc[i_t,2] ))*!radeg
   endif else begin
      Bcon_flg[i_t,*] = !values.f_nan
      surfloc[i_t,*] = !values.f_nan
      bimpact[i_t] = !values.f_nan
      belev[i_t] = !values.f_nan
   endelse
endfor                          ;- i_t
dprint,dlevel=1,verbose=verbose,'calc Bcon end'
;---------------------------------------------------------


;----- store data ----------------------------------------
store_data,'kgy_lmag_Bcon_flg'+suffix $
           ,data={x:dRme.x,y:Bcon_flg,v:[0,1]} $
           ,dlim={yticks:1,yminor:1,ytickname:[' ',' '],ytitle:'Con' $
                  ,zrange:[0,2],zlog:0,spec:1,panel_size:0.15}

store_data,'kgy_lmag_surfloc'+suffix $
           ,data={x:dRme.x,y:surfloc} $
           ,dlim={ytitle:'surfloc'}

store_data,'kgy_lmag_bimpact'+suffix $
           ,data={x:dRme.x,y:bimpact*rL} $
           ,dlim={ytitle:'dist along B!C[km]'}

store_data,'kgy_lmag_belev'+suffix $
           ,data={x:dRme.x,y:belev} $
           ,dlim={ystyle:1,yrange:[-90,90] $
                  ,yticks:6,ytickname:['-90',' ',' ','0',' ',' ','90'] $
                  ,ytitle:'B elev angle!C[deg.]'}

fp_lat = fltarr(n_elements(dRme.x))
fp_lat[*] = ( !dpi/2. - acos( surfloc[*,2] ) )*!radeg
store_data,'kgy_lmag_fp_lat'+suffix $
           ,data={x:dRme.x,y:fp_lat} $
           ,dlim={labels:['fp lat'],labflag:1,colors:[6] $
                  ,ystyle:1,yrange:[-90,90] $
                  ,yticks:6,ytickname:['-90',' ',' ','0',' ',' ','90'] $
                  ,ytitle:'Latitude!C[deg.]'}

fp_lon = fltarr(n_elements(dRme.x))
fp_lon[*] = atan( surfloc[*,1] , surfloc[*,0] )*!radeg
idx_180 = where( fp_lon gt 180 , idx_180_cnt )
if idx_180_cnt gt 0 then fp_lon[idx_180] = fp_lon[idx_180] - 360.
store_data,'kgy_lmag_fp_lon'+suffix $
           ,data={x:dRme.x,y:fp_lon} $
           ,dlim={labels:['fp lon'],labflag:1,colors:[4] $
                  ,ystyle:1,yrange:[-180,180] $
                  ,yticks:4,ytickname:['-180',' ','0',' ','180'] $
                  ,ytitle:'Longitude!C[deg.]'}
;---------------------------------------------------------



end

