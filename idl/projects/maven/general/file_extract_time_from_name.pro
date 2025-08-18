;+
; Function: file_extract_time_from_name
;   Generic function that will extract the time from a file name that has YYYYMMDD_hhmmss as part of the name
;-
function file_extract_time_from_name,filepath,fullpath=fullpath
nf = n_elements(filepath)
if nf eq 0 then return,!values.d_nan
if keyword_set(fullpath) then bname = filepath else bname = file_basename(filepath)
; remove any thing that is not a number or '_'
map = replicate(0b,256)
keep = byte('01234567890_-')
map[keep] = keep
time = replicate(!values.d_nan,nf)
for i= 0L,nf-1 do begin
   bn = bname[i]
   bbn = map[  byte(bn) ]
   w = where(bbn,n)
   if n eq 0 then continue
   segments = strsplit(string(bbn[w]),'_',/extract)
   l = strlen(segments)
   w = where( l eq 8 or l eq 6,nw)
   if nw eq 0 then continue
   tstr = strjoin( segments[w], '_' )
 ;  print,tstr
   time[i] = str2time(tstr,tformat = 'YYYYMMDD_hhmmss')
endfor
return,time
end


