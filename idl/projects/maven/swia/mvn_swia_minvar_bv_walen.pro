;+
;PROCEDURE:	
;	MVN_SWIA_MINVAR_BV_WALEN
;PURPOSE:	
;	Do minimum variance on magnetic field and rotate velocity to same frame 
;       and predict velocity change from Walen relation to test consistency with reconnection exhaust, assuming proton-only, isotropic plasma
;        - 'v?comb' shows Vobs and Vpred for each velocity component
;
;INPUT:		
;
;KEYWORDS:
;	BDATA: tplot variable for the magnetic field (needs to be same frame as velocity)
;	VDATA: tplot variable for the velocity (needs to be same frame as mag field)
;	TRANGE: time range to do minimum variance (will prompt to choose if not set)
;       NDATA: tplot variable for the density
;       TREV: time for sign reversal in Walen relation
;              e.g., trev = 'YYYY-MM-DD/hh:mm:ss' or /trev -> click
;              if not set, the center time of trange is used
;       NOAUTOPM: if set, shows both sign combinations: +/- and -/+
;                 (Def: automatically selects better prediction)
;
;AUTHOR:	J. Halekas	& Yuki Harada (Walen test)
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2015-06-05 16:31:53 -0700 (Fri, 05 Jun 2015) $
; $LastChangedRevision: 17815 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_minvar_bv_walen.pro $
;
;-

pro mvn_swia_minvar_bv_walen, bdata = bdata, vdata = vdata, trange = trange, ndata=ndata, trev=trev, noautopm=noautopm, ev=ev, eig=eig

if not keyword_set(bdata) then bdata = 'mvn_B_1sec_MAVEN_MSO'
if not keyword_set(vdata) then vdata = 'mvn_swim_velocity_mso'

if ~keyword_set(ndata) then ndata = 'mvn_swim_density' ;- for Walen

if not keyword_set(trange) then ctime,trange,npoints = 2 else trange=time_double(trange)

get_data,bdata,data = data

w= where(data.x ge trange(0) and data.x le trange(1))

minvar,transpose(data.y(w,*)),eig,vrot = vrot, lambdas2=ev

store_data,'bminv',data = {x:data.x(w),y:transpose(vrot)}
options,'bminv','labels',['i','j','k']

bminv = transpose(vrot)         ;- for Walen
tbminv = data.x(w)              ;- for Walen

get_data,vdata,data  = vel

vin = transpose(vel.y)
vout = vin

vout(0,*) = eig(0,0)*vin(0,*) + eig(1,0)*vin(1,*) + eig(2,0)*vin(2,*)
vout(1,*) = eig(0,1)*vin(0,*) + eig(1,1)*vin(1,*) + eig(2,1)*vin(2,*)
vout(2,*) = eig(0,2)*vin(0,*) + eig(1,2)*vin(1,*) + eig(2,2)*vin(2,*)

store_data,'vminv',data = {x:vel.x,y:transpose(vout)}
options,'vminv','labels',['i','j','k']

vminv = transpose(vout)         ;- for Walen
tvminv = vel.x                  ;- for Walen


;- Walen test
get_data,ndata,data=ddens
dens = interp( ddens.y, ddens.x, tbminv ,/no_ex)
nt = n_elements(tbminv)
v0 = [ interp(vminv[*,0],tvminv,tbminv[0], /no_ex), $
       interp(vminv[*,1],tvminv,tbminv[0], /no_ex), $
       interp(vminv[*,2],tvminv,tbminv[0], /no_ex) ]
v1 = [ interp(vminv[*,0],tvminv,tbminv[nt-1], /no_ex), $
       interp(vminv[*,1],tvminv,tbminv[nt-1], /no_ex), $
       interp(vminv[*,2],tvminv,tbminv[nt-1], /no_ex) ]
v0arr = transpose(rebin(v0,3,nt))
v1arr = transpose(rebin(v1,3,nt))
b0arr = transpose(rebin(reform(bminv[0,*]),3,nt))
b1arr = transpose(rebin(reform(bminv[nt-1,*]),3,nt))
densarr = rebin(dens,nt,3)

if ~keyword_set(trev) then trev = mean(trange) $
else if typename(trev) eq 'STRING' or typename(trev) eq 'DOUBLE' then trev = time_double(trev) $
else begin
   print,'Click time for sign reversal in Walen relation'
   wait,.5
   ctime,trev,np=1
endelse

w0 = where( tbminv lt trev , comp=w1 )

vpredp0 = v0arr[w0,*] + (bminv[w0,*]/densarr[w0,*]-b0arr[w0,*]/dens[0])*dens[0]^.5 * 21.8122
vpredm0 = v0arr[w0,*] - (bminv[w0,*]/densarr[w0,*]-b0arr[w0,*]/dens[0])*dens[0]^.5 * 21.8122
vpredp1 = v1arr[w1,*] + (bminv[w1,*]/densarr[w1,*]-b1arr[w1,*]/dens[nt-1])*dens[nt-1]^.5 * 21.8122
vpredm1 = v1arr[w1,*] - (bminv[w1,*]/densarr[w1,*]-b1arr[w1,*]/dens[nt-1])*dens[nt-1]^.5 * 21.8122

vpredpm = [ vpredp0, vpredm1 ]
vpredmp = [ vpredm0, vpredp1 ]

split_vec,'vminv'

if keyword_set(noautopm) then begin
   store_data,'vpredpm',data={x:tbminv,y:vpredpm},dlim={linestyle:3}
   store_data,'vpredmp',data={x:tbminv,y:vpredmp},dlim={linestyle:2}
   split_vec,'vpred??'
   store_data,'vicomb',data=['vminv_x','vpredpm_x','vpredmp_x']
   store_data,'vjcomb',data=['vminv_y','vpredpm_y','vpredmp_y']
   store_data,'vkcomb',data=['vminv_z','vpredpm_z','vpredmp_z']
endif else begin
   vinterp = [ [interp(vminv[*,0],tvminv,tbminv, /no_ex)], $
               [interp(vminv[*,1],tvminv,tbminv, /no_ex)], $
               [interp(vminv[*,2],tvminv,tbminv, /no_ex)] ]
   errpm = total( (vinterp-vpredpm)^2 , /nan )
   errmp = total( (vinterp-vpredmp)^2 , /nan )
   if errpm lt errmp then $
      store_data,'vpred',data={x:tbminv,y:vpredpm},dlim={linestyle:2} $
   else $ 
      store_data,'vpred',data={x:tbminv,y:vpredmp},dlim={linestyle:2}
   split_vec,'vpred'
   options,'vpred_?',linestyle=2
   store_data,'vicomb',data=['vminv_x','vpred_x']
   store_data,'vjcomb',data=['vminv_y','vpred_y']
   store_data,'vkcomb',data=['vminv_z','vpred_z']
endelse

end
