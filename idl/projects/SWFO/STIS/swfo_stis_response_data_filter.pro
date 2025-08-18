; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-12-16 11:12:08 -0800 (Sat, 16 Dec 2023) $
; $LastChangedRevision: 32294 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_response_data_filter.pro $
; $ID: $





;  this function returns a true or false depending on if projection of particle direction will
;  pass through a rectangle centered at pos with edges of size width.
function swfo_stis_response_projection_filter,data,pos,width
  a = (where(width eq 0,nw))[0]   ; must be 2 for now
  if nw ne 1 then message,'At least one of width dimensions must be zero'
  if a ne 0 then message, 'Not ready yet'
  one = replicate(1,n_elements(data))
  pos_ = pos # one
  pdist= reform( ( (pos_[a] # one)- data.pos[a]) / data.dir[a]  )          ; projected distance to a-plane
  proj = data.pos + ([1,1,1] # pdist) * data.dir                  ; intersection point of dir line with rectangle's plane
  d  = sqrt(total( (pos_ - proj)^2 ,1) )                       ;  distance to center of rectangle
  ok = pdist gt 0                                                 ; use only particles moving toward rectangle
  ok = ok and proj[1,*] lt pos[1]+width[1]/2.  and proj[1,*] gt pos[1]-width[1]/2.
  ok = ok and (proj[2,*] lt pos[2]+width[2]/2.  and proj[2,*] gt pos[2]-width[2]/2.)
  ;  ok =ok and ((A_rad lt center) or (B_rad lt center))
  return,ok
end



function swfo_stis_response_data_filter,simstat,data,filter=filter, $
  ;     plus_xdir=plus_xdir,minus_xdir=minus_xdir, $
  a_side=a_side,b_side=b_side,o_det=o_det,f_det=f_det,center=center,erange=erange, $
  derange=derange, $
  detname=detname, $
  xdir=xdir,ypos=ypos, $
  fdesc=fdesc, $
  dir = dir, angle = angle,  $
  col_af=col_af,det_af=det_af,impact_bmin=impact_bmin,impact_pos=impact_pos
  filter=0
  str_element,/add,filter,'xdir',xdir
  str_element,/add,filter,'ypos',ypos
  str_element,/add,filter,'dir',dir
  str_element,/add,filter,'angle',angle
  str_element,/add,filter,'a_side',a_side
  str_element,/add,filter,'b_side',b_side
  str_element,/add,filter,'o_det',o_det
  str_element,/add,filter,'f_det',f_det
  str_element,/add,filter,'center',center
  str_element,/add,filter,'erange',erange
  str_element,/add,filter,'derange',derange
  str_element,/add,filter,'col_af',col_af
  str_element,/add,filter,'det_af',det_af
  str_element,/add,filter,'impact_bmin',impact_bmin
  str_element,/add,filter,'impact_pos',impact_pos
  str_element,/add,filter,'detname',detname

  printdat,filter,/val,output=s
  s[0]=' '
  fdesc = strjoin(strcompress(s,/remove_all),', ')
  str_element,/add,filter,'fdesc',fdesc
  n = n_elements(data)
  if n lt 1 then begin
    dprint,'At least 1 data points are required'
    return,-1
  endif
  ok = data.e_tot ge 0                   ; all true
  one = replicate(1,n_elements(data))
  if keyword_set(center) then begin
    det_width=[0,14.4,8.4]
    one = replicate(1,n_elements(data))
    A_pos = [-10,25.,-12.5] # one                              ; note: Z position is a guess.
    A_dist= ( (A_pos[0] # one)- data.pos[0]) / data.dir[2]
    A_proj = data.pos + ([1,1,1] # A_dist) * data.dir
    A_rad  = sqrt(total( (A_pos -A_proj)^2 ,1) )
    B_pos = A_pos *([-1,-1,1] # one)
    B_dist= ( (B_pos[2] # one)- data.pos[2]) / data.dir[2]
    B_proj = data.pos + ([1,1,1]# B_dist) * data.dir
    B_rad  = sqrt(total( (B_pos -B_proj)^2 ,1) )
    ok =ok and ((A_rad lt center) or (B_rad lt center))
  endif
  det_pos = [10.,-25.,-12.5]
  det_width = [0,14.4,8.4]
  ;det_width = [0,10d,10d]
  ;det_pos = [0,0,0]

  col_pos =  det_pos + [30.,0,0]
  col_width = 2 * det_width
  if keyword_set(det_Af) then  ok = ok and swfo_stis_response_projection_filter(data,det_pos,det_width)
  if keyword_set(col_Af) then  ok = ok and swfo_stis_response_projection_filter(data,col_pos,col_width)
  if keyword_set(impact_bmin) then begin
    dpos = (impact_pos # one) -data.pos
    c = crossp_trans(dpos,data.dir)
    b = sqrt(total( c^2, 1 ))
    ok = ok and (b le impact_bmin)
  endif
  if keyword_set(XDIR) then ok = ok and (data.dir[0] * xdir ge 0)
  ;if keyword_set(plus_xdir) then ok = ok and (data.dir[0] gt 0)
  ;if keyword_set(minus_xdir) then ok = ok and (data.dir[0] lt 0)
  if keyword_set(YPOS) then ok = ok and (data.pos[1] * YPOS ge 0)
  angt = 10d   ; 10 degrees
  if keyword_set(angle) then angt = angle
  if keyword_set(DIR)  then begin
    ang = acos( total( data.dir * (dir # one ),1 )/sqrt(total(dir^2.))  )  *180 /!dpi
    ok = ok and (ang lt angt)
  endif
  if keyword_set(a_side) then ok = ok and (data.pos[1] lt 0)
  if keyword_set(b_side) then ok = ok and (data.pos[1] gt 0)
  if keyword_set(F_det)  then ok = ok and (data.pos[0]*data.pos[1] lt 0)
  if keyword_set(O_det)  then ok = ok and (data.pos[0]*data.pos[1] gt 0)
  if keyword_set(erange) then ok = ok and (data.einc ge erange[0] and data.einc lt erange[1])
  if keyword_set(derange) then ok = ok and (data.e_tot ge derange[0] and data.e_tot lt derange[1])
  if keyword_set(detname) then begin
    ;   str_element,simstat,'bmap',bmap
    bmap = simstat.bmap
    ;   if ~keyword_set(bmap) then   bmap = swfo_stis_lut2map(lut=simstat.lut)
    bins = where( strmatch(bmap.name,detname) ,nbins)
    ok1 = 0
    for side=0,1 do for b=0,nbins-1 do ok1 = ok1 or (data.bin[side] eq bins[b])
    ok = ok and ok1
  endif
  w_ok = where(ok,n_ok)
  npart =0
  str_element,simstat,'npart',npart
  s[0]=strjoin(strtrim([n_ok,n,npart],1),'/')
  fdesc = strjoin(strcompress(s,/remove_all),', ')
  str_element,/add,filter,'fdesc',fdesc


  return,ok
end


