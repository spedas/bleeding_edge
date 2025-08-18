;+
;  This is an experimental routine.  It will most likely disappear.
;  Davin Larson
;-


pro data_cache,name,data,set=set,clear=clear,get=get,no_copy=no_copy,help=help

common data_cache_com,dcache

csh = {data_cache,name:'',ptr:ptr_new(),time:0d}
if size(/type,dcache) ne 8 then dcache=csh

if keyword_set(help) then begin
   for i=1,n_elements(dcache)-1 do begin
      printdat,recursemax=help+0,*dcache[i].ptr,varname=dcache[i].name
   endfor   ;   print,transpose(dcache.name)
   return
endif

w = where(dcache.name eq name,nw)

if keyword_set(set) then begin
   csh.name = name
   csh.ptr = ptr_new(data,no_copy=no_copy)
   csh.time = systime(1)

   if nw ge 1 then begin
       ptr_free,ptr_extract(dcache[w])   ; free any data that was there previously  (and all embedded pointers beware!)
       dcache[w] = csh
   endif else begin
       dcache = [dcache,csh]
   endelse
   dprint,dlevel=3,"Cached: ",name
endif

if keyword_set(get) then begin
   if nw ge 1 then begin
       data = *(dcache[w].ptr)
   endif else begin
       data = 0
   endelse
endif

end
