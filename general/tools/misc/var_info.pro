function var_info,x,name=name,recursive=recursive,array=array,format=format
vi = {var_info2,type:0l,n_tags:0l,n_elements:0l,  $
     ndimen:0l,dimen:lonarr(8),name:''}
format = '(( i3,i3,i6,i3,8(i6),"  <",a,">"))'
sz = size(x)
nd  = sz[0]
vi.type = sz[nd+1]
vi.ndimen = nd
if nd gt 0 then  vi.dimen = sz[1:nd]
if vi.type gt 0 then  vi.n_elements = sz[nd+2]
if keyword_set(name) then begin
   vi.name = name
   prefix = name+'.'
endif else prefix = ''

if vi.type eq 8 then begin
   if vi.n_elements eq 1 then begin   ;force 1 element structures into scalers
      vi.ndimen = 0
      vi.dimen = 0
   endif
   vi.n_tags = n_tags(x)
   if keyword_set(recursive) then begin
      tags = tag_names(x)
      for i=0,vi.n_tags-1 do begin
         vi = [ vi, var_info(x[0].(i),/recursive,name=prefix+tags[i]) ]
      endfor
   endif   
endif
if keyword_set(array) then begin
  ar = lonarr(12,n_elements(vi))
  ar(0,*) = vi.type
  ar(1,*) = vi.n_tags
  ar(2,*) = vi.n_elements
  ar(3,*) = vi.ndimen
  ar(4:11,*) = vi.dimen
  return,ar
endif
return,vi
end
