;+
; PROCEDURE:
;       kgy_mom_calc
; PURPOSE:
;       Computes velocity moments from Kaguya PACE data
; KEYWORDS:
;       trange: time range
;       sensor: 0: ESA-S1, 1: ESA-S2, 2: IMA, 3: IEA (Def. all) 
; CREATED BY:
;       Yuki Harada on 2018-05-11
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2022-01-16 20:35:30 -0800 (Sun, 16 Jan 2022) $
; $LastChangedRevision: 30515 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_mom_calc.pro $
;-

pro kgy_mom_calc, trange=trange, sensor=sensor, cntcorr=cntcorr, infoangle=infoangle, verbose=verbose, conv16x64to4x16=conv16x64to4x16, nointerp=nointerp, thld_gf=thld_gf, temperature=temperature

@kgy_pace_com

if size(sensor,/type) eq 0 then sensor=[0,1,2,3]
if size(cntcorr,/type) eq 0 then cntcorr = 1 ;- count correction by default
if size(infoangle,/type) eq 0 then infoangle = 1
if size(conv16x64to4x16,/type) eq 0 then conv16x64to4x16 = 1
tr = timerange(trange)

for is=0,n_elements(sensor)-1 do begin ;- loop through sensors

skip = 0
case sensor[is] of
   0: begin
      sensorname = 'ESA-S1'
      sensornname = 'esa1'
      if size(esa1_header_arr,/tname) eq 'STRUCT' then $
         header_arr = esa1_header_arr
      get3d_func = 'kgy_esa1_get3d'
   end
   1: begin
      sensorname = 'ESA-S2'
      sensornname = 'esa2'
      if size(esa2_header_arr,/tname) eq 'STRUCT' then $
         header_arr = esa2_header_arr
      get3d_func = 'kgy_esa2_get3d'
   end
   2: begin
      sensorname = 'IMA'
      sensornname = 'ima'
      if size(ima_header_arr,/tname) eq 'STRUCT' then $
         header_arr = ima_header_arr
      get3d_func = 'kgy_ima_get3d'
   end
   3: begin
      sensorname = 'IEA'
      sensornname = 'iea'
      if size(iea_header_arr,/tname) eq 'STRUCT' then $
         header_arr = iea_header_arr
      get3d_func = 'kgy_iea_get3d'
   end
   else: skip = 1
endcase

if skip then continue
if size(header_arr,/tname) ne 'STRUCT' then continue

times = $
   time_double( string(header_arr[*].yyyymmdd,format='(i8.8)') $
                +string(header_arr[*].hhmmss,format='(i6.6)'), $
                tformat='YYYYMMDDhhmmss' ) $
   + header_arr[*].time_resolution / 2.d3
indexes = header_arr[*].index

wt = where( times ge tr[0] and times lt tr[1] , nwt )
if nwt eq 0 then continue

times = times[wt]
indexes = indexes[wt]
s = sort(times)
stimes = times[s]
sindexes = indexes[s]
idx_uniq = uniq(stimes)

dens = make_array(value=!values.f_nan,n_elements(idx_uniq))
vel = make_array(value=!values.f_nan,n_elements(idx_uniq),3)
if keyword_set(temperature) then temp = make_array(value=!values.f_nan,n_elements(idx_uniq),4)

for i=0l,n_elements(idx_uniq)-1 do begin
   if i mod 10 eq 0 then dprint,dlevel=1,verbose=verbose,'mom ',sensornname,i,' /',n_elements(idx_uniq)-1,' : '+time_string(stimes[idx_uniq[i]])

   theindex = sindexes[idx_uniq[i]]
   dat = call_function(get3d_func,index=theindex,sabin=0,cntcorr=cntcorr,infoangle=infoangle)
   if dat.valid ne 1 then continue

   if keyword_set(conv16x64to4x16) then dat = kgy_pace_16x64to4x16(dat)
   if sensor[is] ge 2 and ~keyword_set(nointerp) and dat.nphi gt 60 then begin
      dat = conv_units(dat,'eflux')
      dat = kgy_pace_interp(dat,thld_gf=thld_gf) ;- interp in eflux
      dat.gfactor = 1. ;- make sure eflux to df conversion works
   endif

   dens[i] = kgy_n_3d(dat)
   vel[i,*] = kgy_v_3d(dat)
   if keyword_set(temperature) then temp[i,*] = kgy_t_3d(dat)

endfor                          ;- i

store_data,'kgy_'+sensornname+'_momc_dens', $
           data={x:stimes[idx_uniq],y:dens}, $
           dlim={ytitle:sensorname+'!cN!c[cm!u-3!n]'}
store_data,'kgy_'+sensornname+'_momc_vel', $
           data={x:stimes[idx_uniq],y:vel}, $
           dlim={ytitle:sensorname+'!cV!c[km/s]',colors:'bgr',labflag:1, $
                 labels:['Vx','Vy','Vz'],constant:0, $
                 spice_frame:'SELENE_M_SPACECRAFT'}
store_data,'kgy_'+sensornname+'_momc_vabs', $
           data={x:stimes[idx_uniq],y:total(vel^2,2)^.5}, $
           dlim={ytitle:sensorname+'!cV!c[km/s]'}
if keyword_set(temperature) then $
   store_data,'kgy_'+sensornname+'_momc_temp', $
              data={x:stimes[idx_uniq],y:temp}, $
              dlim={ytitle:sensorname+'!cT!c[eV]',labflag:1, $
                    labels:['Tx','Ty','Tz','Tavg']}


endfor                          ;- is

print,''
print,'=== Warning ==='
print,'This routine is still experimental and the results may include significant errors.'
print,'Please contact PI (Y. Saito) if you are to use PACE velocity moment data for publication.'
print,'==============='
print,''

end
