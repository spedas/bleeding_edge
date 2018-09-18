;+
;NAME: ptr_extract
;Function: ptrs = ptr_extract(p,EXCEPT=EXCEPT)
;Purpose:
;   Recursively searches the input (of any type) and returns an array of all
;   pointers found.
;   This is useful for freeing pointers contained within some complicated
;   structure heirachy or pointer list.
;   if no pointers are found then a scaler null pointer is returned.
;   This routine ignores object pointers!
;Keywords:
;   EXCEPTPTRS = an array of pointers that should not be included in the output.
;Created by Davin Larson. May 2002.
;-
function ptr_extract,p,exceptptrs=exceptptrs0
dt = size(/type,p)
ret = ptr_new()
ret_index=0
if dt eq 10 then begin     ; Pointers
   n  = n_elements(p)
   if n_elements(exceptptrs0) ne 0 then exceptptrs=exceptptrs0 else exceptptrs = ptr_new()
   exc_index=n_elements(exceptptrs)
;   dprint,'n=',n,'  nexc=',exc_index,dlevel=2
   for i=0,n-1 do begin
      if ptr_valid(p[i]) eq 0 then continue                        ; skip null pointers
      if total(exceptptrs eq p[i]) gt 0 then continue              ; already encountered
      append_array,ret,p[i],index = ret_index,/fillnan
      append_array,exceptptrs,p[i],index=exc_index,/fillnan
      r = ptr_extract(*p[i],exceptptrs=exceptptrs)
      if keyword_set(r) then begin
        append_array,ret,r,index = ret_index ,/fillnan       
        append_array,exceptptrs,r,index=exc_index,/fillnan
      endif
   endfor
   append_array,ret,index=ret_index
   append_array,exceptptrs,index=exc_index
endif

if dt eq 8 then begin    ; Structures
   if n_elements(exceptptrs0) ne 0 then exceptptrs=exceptptrs0 else exceptptrs = ptr_new()
   exc_index=n_elements(exceptptrs)
   tags = tag_names(p)
   ntag = n_elements(tags)
;   dprint,'ntag=',ntag,dlevel=2
   for i=0,ntag-1 do begin
;      dprint,'tag: ',tags[i],dlevel=3
      r = ptr_extract(p.(i),exceptptrs=exceptptrs)
      if keyword_set(r) then begin
        append_array,ret,r,index=ret_index,/fillnan
        append_array,exceptptrs,r,index=exc_index,/fillnan
      endif
   endfor
   append_array,ret,index=ret_index
   append_array,exceptptrs,index=exc_index
end

;w = where(ret ne nul,nw)
;dprint,w,nw,dlevel=3,/phelp
;return,nw gt 0 ? ret[w] : nul

return, ret
end

