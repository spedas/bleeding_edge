
pro st_part_moments,tname=tname,probe=probe,get_pads=get_pads,get_moments=get_moments $
      ,get_secondary=get_secondary,bins=bins,esteps=esteps

;   get_pads = keyword_set(dopad)
   nan = !values.f_nan
   units='eflux'
   times = st_swea_dist(tname=tname,probe=probe,/times)
   prefix = tname
   str_replace,prefix,'_Distribution',''

   nt = n_elements(times)
   if keyword_set(get_moments) then   moms=replicate(moments_3d(),nt)
   if keyword_set(get_pads) then begin
       pads = replicate(nan,nt,16,8)
       pads_ang = pads
   endif
   if keyword_set(get_secondary) then begin
      secondary = fltarr(nt)
      if not keyword_set(bins) then bins=1
   endif
   if keyword_set(bins) then begin
      adist = replicate(nan,nt,16)
      if n_elements(bins) gt 1 then wbins=where(bins) else wbins = indgen(80)
   endif

   for i=0l,nt-1 do begin
      dat = st_swea_dist(tname=tname,index=i)
;      dat.sc_pot = 15
      if keyword_set(moms) then   moms[i] = moments_3d( dat )
      udat = conv_units(dat,units)
      if keyword_set(bins) then begin
         omni_eflux =average(udat.data[*,wbins],2)
         adist[i,*] = omni_eflux
         if keyword_set(get_secondary) then begin
            secondary[i] = st_swea_secondary_flux(udat.energy[*,0],omni_eflux,param=par_sec)
         endif
      endif
      if  keyword_set(pads) then begin
         pd = pad(udat)
         pads[i,*,*] = pd.data
         pads_ang[i,*,*] = pd.angles
      endif
      dprint,i,' of ',nt,dwait=5.
   endfor

   if keyword_set(moms) then begin
      tnam = strlowcase(tag_names(moms))
      mindex = strfilter(tnam,'time,valid,mass',delimiter=',',/negate,/index)

      for m = 0,n_elements(mindex)-1 do begin
         mdat = moms.(mindex[m])
         if size(/n_dimen,mdat) eq 2 then mdat = transpose(mdat)
         store_data,prefix+'_mom_'+tnam[mindex[m]],data={x:moms.time,y:mdat}
      endfor
   endif

   if keyword_set(pads) then begin
      energy = average(pd.energy,2)
      angle = average(pads_ang,2)
      store_data,prefix+'_pad',data={x:times,y:pads,v1:energy,v2:angle},dlimit={spec:1}
   endif

   if keyword_set(adist) then begin
      energy = average(udat.energy,2)
      ;angle = average(pads_ang,2)
      store_data,prefix+'_en',data={x:times,y:adist,v:energy},dlimit={spec:1,ylog:1,zlog:1}
   endif

   if keyword_set(secondary) then begin
      store_data,prefix+'_secondary',data={x:times,y:secondary}
   endif

end


