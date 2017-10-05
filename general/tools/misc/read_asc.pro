function string_value,str,error =err
  err = execute('x='+str)
  if err eq 0 then x=!values.f_nan
  return,x
end


function strings_to_structure,strings,structure
  ;new_struct = structure
  for i=0,n_elements(strings)-1 do begin
     s = strings[i]
     if strpos(s,'=') gt 0 then begin
          ss = strsplit(s,'=',/extract)
;      printdat,ss        
          name = (reverse(strsplit(ss[0],' ',/extract)))[0]
;          printdat,name
          value = string_value(SS[1],error=err)
          if err ne 0 then str_element,/add,structure,idl_validname(name),value    
     endif
  endfor
  return,structure
end





;+
;FUNCTION:  data=read_asc(filename)
;PURPOSE:
;   Reads data from an ascii file and puts data in an array of structures.
;   Columns of data should be delimited by spaces.
;   Data is returned as an array of structures. The elements of the structure
;   correspond to the columns of the file.
;CALLING PROCEDURE:
;   read_ascii,data,'file.dat'
;KEYWORDS:
;   TAGS:  If set then the labels in the text line
;      preceeding the data will be used for the default struct tag names.
;      (There should be one label per column of data)
;   FORMAT:  a structure that specifies the output format
;      of the data.  For example if the input file has the
;      following data:
;      Year Day  secs    Vx     Vy     Vz      N
;      1996 123  13.45  512.3  -10.3   10.5   5.3
;      the format could be specified as:
;   FORMAT={year:0,day:0,sec:0.d,v:fltarr(3),n:0.}
;   if this keyword is not specified then a default structure will be created.
;CREATED BY: Davin Larson
;-

function read_asc,filenames,header_info,format=f,verbose=verbose,tags=filetags,time=time $
  ,append=append $
  ,seperators=seps $
  ,ctype=ctype ,remap=remap $
  ,nheader=nheader , headers=headers  $
  ,tokens=tokens, thisfile=thisfile  $
  ,compress = compress  $
  ,conv_time=conv_time $
  ,filter=filter, double=double
;  ,no_conv_time=no_conv_time

if keyword_set(append) then data=append else data=0

if keyword_set(thisfile) then begin
    stack = scope_traceback(/structure)
    filenames = stack[scope_level()-2].filename
    tokens = ';'
endif
linenumber=0

if not keyword_set(filenames) then filenames=dialog_pickfile(filter=filter)


on_ioerror,badfile
for fn=0,n_elements(filenames)-1 do begin
filename = filenames[fn]
if not keyword_set(filename) then return,data

if n_elements(compress) eq 0 then compress = (strmid(filename,2,3,/reverse_offset) eq '.gz')
;dprint,dlevel=3,'compress=',compress
openr,lun,filename,/get_lun,compress=compress

if not keyword_set(ctype) then begin
  ctype = bytarr(256)
  ctype[[32,9]] = 1                 ; white space
  ctype[byte('.-0123456789')] =2    ; numbers
endif


s = ''

if keyword_set(f) and keyword_set(conv_time) then begin
   time = strpos(tag_names_r(f),'TIME') ge 0
   wtime = where(time,ntime)
endif

;rec = 0l
rec = keyword_set(data) * n_elements(data)
max = rec

for i=0,(keyword_set(nheader) ? nheader : 0)-1 do begin
   linenumber++
   readf,lun,s
   if i eq 0 then headers = s    else    headers = [headers,s]
   if keyword_set(verbose) then print,s
endfor

if not keyword_set(seps) then seps = ' ,'

return_header_info = arg_present(header_info)

while not eof(lun) do begin
  linenumber++
  readf,lun,s
  if keyword_set(tokens) then begin
     pos = strpos(s,tokens)
     if pos ne 0 then continue
     s = strmid(s,strlen(tokens))
  endif

  if keyword_set(verbose) then print,s
  if return_header_info then begin
        header_info = strings_to_structure(s,header_info)
  endif
  bt = byte(s)
  nbt = n_elements(bt)
  if keyword_set(remap) then begin
     bt = remap[bt]
     s = string(bt)
  endif
  j = 0
  while (j lt nbt-1) and (ctype[bt[j]] eq 1) do j=j+1   ; skip white space
  if ctype[bt[j]] eq 2 then begin    ; numbers encountered
    if not keyword_set(f) then begin       ; define structure if needed
       ps = strsplit(strcompress(strtrim(s,2)),seps,/extract)
       n = n_elements(ps)
       type = (strpos(ps,'.') ge 0)  or (strpos(ps,'e') ge 0) or strlowcase(ps) eq 'nan'
       time = (strpos(ps,'/') ge 0)
       if keyword_set(filetags) then tags=strsplit(strcompress(strtrim(ls,2)),' ',/extract) $
       else tags='v'+strtrim(indgen(n),2)
       n= n_elements(tags)
       wtime = where(time,ntime)
       if ntime gt 0 then begin
          tags[wtime] = 'TIME'
          type[wtime] = 2
       endif
       for i=0,n-1 do begin
           case type[i] of
              0: fill = 0l
              1: fill = 0.
              2: fill = 0.d
           endcase
           if i eq 0 then  f = create_struct(idl_validname(tags[0],/convert_all),fill)  $
           else f = create_struct(f,idl_validname(tags[i],/convert_all),fill)
       endfor
    endif
    f0 = f
    if rec ge max then begin        ;Enlarge data array (if neccesary)
       add = floor(max * .5 + 100)
       if max ne 0 then data=[data,replicate(f0,add)]  $
       else data = replicate(f0,add)
       max = max+add
    endif
    if keyword_set(ntime) then begin
;       ps = str_sep(strcompress(strtrim(s,2)),' ')
       s = strcompress(strtrim(s,2))
       nt = n_tags(f0)
       pos1=0
       for i=0,nt-1 do begin
          pos2 = strpos(s,' ',pos1)
          if i eq (nt-1) then  pos2 = strlen(s)
          ps = strmid(s,pos1,pos2-pos1)
          pos1=pos2+1
          if time[i] then f0.(i)=time_double(ps) else begin
            x=f0.(i)
            reads,ps,x
            f0.(i) = x
          endelse
       endfor
    endif else  reads,s,f0
    data[rec]=f0
    rec = rec+1
  endif else begin
    if strlen(s) gt 1 then ls = s
;    if keyword_set(verbose) then print,s
  endelse
endwhile

if rec ne 0 then data=data[0:rec-1]

free_lun,lun
append = 1
endfor

return,data

badfile:
dprint,!err_string
dprint,'linenumber=',linenumber
dprint,'Invalid file: '+filename
if keyword_set(lun) then free_lun,lun
return,data


end

