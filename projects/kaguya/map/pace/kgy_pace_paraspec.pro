;+
; PROCEDURE:
;       kgy_pace_paraspec
; PURPOSE:
;       generates energy spectra for 6 pitch angle ranges:
;       parapara  paramid  paraperp  antiperp  antimid  antipara
;       0-30      30-60    60-90     90-120    120-150  150-180
; CALLING SEQUENCE:
;       kgy_pace_paraspec, sensor=0
; KEYWORDS:
;       trange: time range
;       sensor: 0: ESA-S1, 1: ESA-S2, 2: IMA, 3: IEA (Def. [0,1])
;       units: (Def: 'eflux')
; CREATED BY:
;       Yuki Harada on 2016-10-26
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2016-10-26 10:34:33 -0700 (Wed, 26 Oct 2016) $
; $LastChangedRevision: 22200 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_pace_paraspec.pro $
;-

pro kgy_pace_paraspec, sensor=sensor, thld_pa=thld_pa, thld_nbin=thld_nbin, suffix=suffix, trange=trange, infoangle=infoangle, units=units, cntcorr=cntcorr

if ~keyword_set(units) then units = 'eflux' else units = strlowcase(units)
if size(sensor,/type) eq 0 then sensor = [0,1]
if ~keyword_set(thld_pa) then thld_pa = 30.
if ~keyword_set(thld_nbin) then thld_nbin = 1
if ~keyword_set(suffix) then suffix = ''
if size(infoangle,/type) eq 0 then infoangle = 1
if keyword_set(cntcorr) then suffix = suffix + '_c'
if keyword_set(trange) then tr = time_double(trange)

for i_s=0,n_elements(sensor)-1 do begin
   if sensor[i_s] eq 0 then sname = 'esa1'
   if sensor[i_s] eq 1 then sname = 'esa2'
   if sensor[i_s] eq 2 then sname = 'ima'
   if sensor[i_s] eq 3 then sname = 'iea'

   getfunc = 'kgy_'+sname+'_get3d'
   t = call_function(getfunc,/gettimes)
   if n_elements(tr) eq 2 then begin
      w = where( t ge tr[0] and t le tr[1] ,nw )
      if nw eq 0 then return
      t = t[w]
   endif

   nt = n_elements(t)
   energy = replicate(!values.f_nan,nt,32)

   parapara = replicate(!values.f_nan,nt,32) ;- para
   antipara = replicate(!values.f_nan,nt,32)

   paramid = replicate(!values.f_nan,nt,32) ;- mid
   antimid = replicate(!values.f_nan,nt,32)

   paraperp = replicate(!values.f_nan,nt,32) ;- perp
   antiperp = replicate(!values.f_nan,nt,32)

   for i_t=0l,nt-1 do begin
      if i_t mod 10 eq 0 then dprint,sname,i_t,'/',nt,': ',time_string(t[i_t])
      getfunc = 'kgy_'+sname+'_get3d'
      ddd = call_function(getfunc,t[i_t],sabin=0,infoangle=infoangle,cntcorr=cntcorr)
      if ddd.nenergy ne 32 or ddd.valid eq 0 then continue
      if ddd.sensor le 1 and ddd.svs ne 6 then continue

      ddd = kgy_pace_16x64to4x16(ddd,/sabin,infoangle=infoangle)

      dddf = conv_units(ddd,units)
      bdir = ddd.magf/total(ddd.magf^2)^.5

      w = where(~ddd.bins,nw) & ww = ddd.bins * 1.
      if nw gt 0 then ww[w] = !values.f_nan
      energy[i_t,*] = average(ddd.energy*ww,2,/nan)

      sphere_to_cart,1.,ddd.theta,ddd.phi,vx,vy,vz
      vdotb = vx*bdir[0] + vy*bdir[1] + vz*bdir[2]

      pang = acos(vdotb)*!radeg

      w = where(pang lt thld_pa and ddd.bins eq 1 , nw )
      if nw ge thld_nbin then begin
         ww = ddd.data*0.
         ww[w] = 1.
         if units eq 'counts' then parapara[i_t,*] = total(/nan,dddf.data*ww,2) else parapara[i_t,*] = total(/nan,dddf.data*dddf.domega*ww,2)/total(/nan,dddf.domega*ww,2)
      endif

      w = where(pang gt 180-thld_pa and ddd.bins eq 1, nw )
      if nw ge thld_nbin then begin
         ww = ddd.data*0.
         ww[w] = 1.
         if units eq 'counts' then antipara[i_t,*] = total(/nan,dddf.data*ww,2) else antipara[i_t,*] = total(/nan,dddf.data*dddf.domega*ww,2)/total(/nan,dddf.domega*ww,2)
      endif

      w = where(pang gt thld_pa and pang lt 90-thld_pa and ddd.bins eq 1 , nw )
      if nw ge thld_nbin then begin
         ww = ddd.data*0.
         ww[w] = 1.
         if units eq 'counts' then paramid[i_t,*] = total(/nan,dddf.data*ww,2) else paramid[i_t,*] = total(/nan,dddf.data*dddf.domega*ww,2)/total(/nan,dddf.domega*ww,2)
      endif

      w = where(pang lt 180-thld_pa and pang gt 90+thld_pa and ddd.bins eq 1, nw )
      if nw ge thld_nbin then begin
         ww = ddd.data*0.
         ww[w] = 1.
         if units eq 'counts' then antimid[i_t,*] = total(/nan,dddf.data*ww,2) else antimid[i_t,*] = total(/nan,dddf.data*dddf.domega*ww,2)/total(/nan,dddf.domega*ww,2)
      endif

      w = where(pang gt 90-thld_pa and pang lt 90 and ddd.bins eq 1 , nw )
      if nw ge thld_nbin then begin
         ww = ddd.data*0.
         ww[w] = 1.
         if units eq 'counts' then paraperp[i_t,*] = total(/nan,dddf.data*ww,2) else paraperp[i_t,*] = total(/nan,dddf.data*dddf.domega*ww,2)/total(/nan,dddf.domega*ww,2)
      endif

      w = where(pang lt 90+thld_pa and pang gt 90 and ddd.bins eq 1, nw )
      if nw ge thld_nbin then begin
         ww = ddd.data*0.
         ww[w] = 1.
         if units eq 'counts' then antiperp[i_t,*] = total(/nan,dddf.data*ww,2) else antiperp[i_t,*] = total(/nan,dddf.data*dddf.domega*ww,2)/total(/nan,dddf.domega*ww,2)
      endif

   endfor                       ;- i_t


   store_data,'kgy_'+sname+'_parapara_en_'+units+suffix, $
              data={x:t,y:parapara,v:energy}, $
               dlim={datagap:63,yrange:minmax(energy),ystyle:1,ylog:1,spec:1, $
                     yticklen:-.01,zlog:1,ztitle:units,minzlog:1e-30, $
                     ytitle:'kgy '+sname+'!cpara-B!cEnergy [eV]'}
   store_data,'kgy_'+sname+'_antipara_en_'+units+suffix, $
              data={x:t,y:antipara,v:energy}, $
               dlim={datagap:63,yrange:minmax(energy),ystyle:1,ylog:1,spec:1, $
                     yticklen:-.01,zlog:1,ztitle:units,minzlog:1e-30, $
                     ytitle:'kgy '+sname+'!canti-B!cEnergy [eV]'}

   store_data,'kgy_'+sname+'_paramid_en_'+units+suffix, $
              data={x:t,y:paramid,v:energy}, $
               dlim={datagap:63,yrange:minmax(energy),ystyle:1,ylog:1,spec:1, $
                     yticklen:-.01,zlog:1,ztitle:units,minzlog:1e-30, $
                     ytitle:'kgy '+sname+'!cpara-B mid!cEnergy [eV]'}
   store_data,'kgy_'+sname+'_antimid_en_'+units+suffix, $
              data={x:t,y:antimid,v:energy}, $
               dlim={datagap:63,yrange:minmax(energy),ystyle:1,ylog:1,spec:1, $
                     yticklen:-.01,zlog:1,ztitle:units,minzlog:1e-30, $
                     ytitle:'kgy '+sname+'!canti-B mid!cEnergy [eV]'}

   store_data,'kgy_'+sname+'_paraperp_en_'+units+suffix, $
              data={x:t,y:paraperp,v:energy}, $
               dlim={datagap:63,yrange:minmax(energy),ystyle:1,ylog:1,spec:1, $
                     yticklen:-.01,zlog:1,ztitle:units,minzlog:1e-30, $
                     ytitle:'kgy '+sname+'!cpara-B perp!cEnergy [eV]'}
   store_data,'kgy_'+sname+'_antiperp_en_'+units+suffix, $
              data={x:t,y:antiperp,v:energy}, $
               dlim={datagap:63,yrange:minmax(energy),ystyle:1,ylog:1,spec:1, $
                     yticklen:-.01,zlog:1,ztitle:units,minzlog:1e-30, $
                     ytitle:'kgy '+sname+'!canti-B perp!cEnergy [eV]'}

endfor                          ;- i_s


end
