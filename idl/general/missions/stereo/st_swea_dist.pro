



function st_swea_dist,time,index=index,times=times,tname=tname,probe=probename

common st_swea_dist_com, last_tname  ;,  last_ptrs, foo1, foo2

if not keyword_set(tname) then begin
   if not keyword_set(last_tname) then last_tname = 'sta_SWEA_Distribution'
   tname = last_tname
   if keyword_set(probename) then begin
      probe = strlowcase(strmid(probename,0,1))
      strput,tname,probe,2
      last_tname =tname
   endif
endif

get_data,tname,ptr_str=ptrs

if ~keyword_set(ptrs) || 0 then begin
  dprint,'No data found for: "',tname,'". Run "ST_SWEA_LOAD" first'
  return,0    ;  {stereo_swea_dist3d}  ; error
endif

last_tname = tname

dat3d = *ptrs.dat3d

if keyword_set(times) then return, *ptrs.x

if n_elements(index) eq 0 then begin
   if not keyword_set(time) then ctime,time,npoints=1
   if not keyword_set(time) then return,0
   index =  round(interp( indgen(n_elements(*ptrs.x) ), *ptrs.x, time ,/no_extrapolate))
endif

if n_elements(index) gt 1 then begin
    di = index[1]-index[0]+1
    dprint,'Averaging 3D distributions...'
    for i=0,di-1 do $
        totdat = sum3d(totdat,st_swea_dist(tname=tname,index=index[i]))
    return,dat

endif

dat3d.index = index
dat3d.time = (*ptrs.x)[index]
dat3d.end_time = dat3d.time + 2.               ; NOTE inconsistency !!!!
dat3d.trange = dat3d.time + [-1.,+1]
dat3d.data = transpose( reform((*ptrs.y)[index,*,*]))
dat3d.valid =1
if ptr_valid(ptrs.magf) && keyword_set(*ptrs.magf) then dat3d.magf = (*ptrs.magf)[index,*]

return,dat3d
end


