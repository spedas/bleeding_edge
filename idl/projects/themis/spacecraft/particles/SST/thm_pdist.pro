


; Commented out to allow compiling for virtual machines (was conflicting
; with actual thm_part_dist) 
;
;function thm_part_dist,dformat,time,index=index,times=times,_extra=ex
;;  if keyword_set(ex) then dprint,ex,phelp=2
;  return,thm_pdist(dformat,time,index=index,times=times)
;end





;+
;  $Id: $
;-
function thm_pdist,dformat,time,index=index,times=times,$
                      badbins2mask=badbins2mask,cursor=cursor,_extra=ex

if not keyword_set(time) and not keyword_set(index) and not keyword_set(dformat) then cursor = 1

if keyword_set(cursor) then begin
   ctime,time,vname=vname
   ts=time_string(time)
   dprint,vname,/phelp
   dprint,ts,/phelp
   if not keyword_set(dformat) then begin
      dformat = strmid(vname,0,8)
      dformat = dformat[0]
      dprint,dformat,/phelp
   endif
endif

;if keyword_set(dformat) then begin
;   probe = strmid(dformat,2,1)
;   type  = strmid(dformat,4,4)
;endif else dformat = 'th'+probe+'_'+type


if strmid(dformat,5,1) eq 'e' then begin           ; ESA data request
;  dprint,dlevel=4,'Getting ESA data: ',dformat
;  if n_elements(time) gt 1 then begin
      if n_elements(index) eq 0 then begin
         atimes = call_function('get_'+dformat, /times)
         if keyword_set(times) then return,atimes
         ind =round( interp(dindgen(n_elements(atimes)),atimes,minmax(time) ) )
      endif else ind = minmax(index)
      if ind[1] ne ind[0] then dprint,dlevel=3,'Averaging ',dformat,' :',ind
      for i=ind[0],ind[1] do begin
         dat0 = call_function('get_'+dformat, index=i)
         dat = sum3d(dat,dat0)
      endfor
;  endif else   dat = thm_part_dist(dformat,time,index=index,times=times)
  return,dat

endif


; From this point on only a single SST 3d structure is returned

get_data,dformat+'_data',ptr=dptr
;data_cache,'th'+probe+'_sst_raw_data',data,/get

if not keyword_set(dptr) then begin
   dprint,dlevel=0,'No data loaded for ',dformat
   return,0
endif
mdistdat = *dptr.mdistdat

if keyword_set(times) then  return, mdistdat.times

if n_elements(index) eq 0 then begin
    if keyword_set(time) eq 0 then begin
        ctime,time
    endif
    index=round( interp(dindgen(n_elements(mdistdat.times)),mdistdat.times,time) )
endif

if n_elements(index) ne 1 then begin
   dprint,'Getting multiple distributions'   ;   message,'time/index ranges not allowed yet',/info
   for i=index[0],index[1] do begin
        dat = thm_pdist(dformat,index=i,_extra=ex)
        sdat = sum3d(sdat,dat)
   endfor
   return,sdat
endif

varn = mdistdat.varn[index]
distdat = *(mdistdat.distptrs[varn])
vind = mdistdat.index[index]
dist = *distdat.dat3d

;dprint,dlevel=3,'index=',index,'ind=',vind

spin_period = 3.
dist.index = index
dist.time = (*distdat.times)[vind]
dist.end_time = dist.time+spin_period
dist.data= thm_part_decomp16((*distdat.data)[vind,*,*])
dist.magf = keyword_set(distdat.magf) ? (*distdat.magf)[vind,*] : !values.f_nan
dist.cnfg= (*distdat.cnfg)[vind]
dist.atten = (*distdat.atten)[vind]
dist.units_name = 'Counts'
dist.valid=1

if keyword_set(badbins2mask) then begin
   bad_ang = badbins2mask
   if array_equal(badbins2mask, -1) then begin
      print,''
      dprint,'WARNING: BADBINS2MASK array is empty. No bins masked for ', $
                      'th'+probe,'_psef data.'
      print,''
   endif else begin
      dist.bins[*,bad_ang] = 0
   endelse
endif

return,dist
end
