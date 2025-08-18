;The following function is not finished yet....
function pformat,s,n,title=title,format=format,width=width,recurse=recurse
  title = ''
  format = '('
  if n_elements(n) eq 0 then n=1
  dt = data_type(s,n_elements=nel,ndimen=ndim)

  if dt eq 8 then begin
  endif

  typ = [0,3,3,3,5,5,9,7,8,9,0]

  case typ[dt] of
  3:begin   ; integer
      mm = minmax(s)
      width = max( floor(alog10(abs(mm) > 1)) + 1 + (mm lt 0) )
      f=strcompress(string(n,'(i',width),/rem) + '," ")'
    end
  5:begin  ; floating point
      mm = minmax(s)
      width = max( floor(alog10(abs(mm) > 1)) + 1 + (mm lt 0) ) +2
      nfrac= (width - 1 - max(mm lt 0)) > 0
      if width le 8 then begin
        f=strcompress(string(n,'(f',width,'.',nfrac),/rem) + '," ")'
      endif else begin
        width=width+4
        f=strcompress(string(n,'(e',width,'.',nfrac),/rem) + '," ")'
      endelse
    end
  7:begin   ; strings
      width = max(strlen(s))
      f = strcompress(string(n,'(a',width),/rem) + '," ")'
    end
  8:begin
      print,'structure'
      f=strcompress(string(n,'('),/rem)
      for i=0,n_tags(s)-1 do begin
        f = f + pformat(s.(i)) + '," ")'
      endfor
      f = f+')'
    end
  else:
  endcase
  if not keyword_set(recurse) then f = '('+f+')'
  return,f

;  tn = tag_names(s)
;  for j=0,n_tags(s)-1 do begin
;     dt = data_type(s.(j),n_elem=nd)
;     sz = sizes[dt]
;     if nd eq 1 then jtit = string(/print,tn[j],f='(a'+strtrim(sz,2)+'," ")')  $
;     else jtit = string(/print,tn[j]+'['+strtrim(indgen(nd),2)+']',f='(20(a'+strtrim(sz)+'," "))')
;     title = title+jtit
;     format = format + strtrim(nd,2)+'(' + forms(dt) + '," "),'
;  endfor
;  format = format+')'
;  printf,lun,title
;  print,format
end



;+
;PROCEDURE:  print_struct, data, tags=tags
;PURPOSE:
;   prints data in an array of structures.
;CALLING PROCEDURE:
;   print_struct, data
;KEYWORDS:
;   TAGS:  tagnames of structure to print
;
;CREATED BY: Davin Larson, 1997
;-

pro print_struct,str,tags=tags,format=format,file=file,append=append,width=width

if size(/type,str) ne 8 then begin
  dprint,'Input should be an array of structures'
  return
endif

forms = strsplit(/extract,' i3 i4 i5 f7.3 f8.4 a10 a10',' ',/preserve_null)

forms2 = strsplit(/extract,' i i i g g x a x x x x i i i i',' ',/preserve_null)
sizes = [0,3,4,5,9,10,0,40,0,0,0,0,12,12,12,12]

lun=-1
if keyword_set(file) then begin
  if not keyword_set(width) then width = 500
  if size(/type,file) eq 7 then begin
    if keyword_set(append) then openu,lun,file,/get_lun,/append,width=width  $
    else openw,lun,file,/get_lun,width=width
    append = 1
  endif else begin
    if size(/type,file) eq 2 then lun=file
  endelse
endif

if not keyword_set(tags) then tg=tag_names(str) else begin
  if ndimen(tags) eq 0 then tg = strupcase(strsplit(/extract,tags,' ')) else tg=strupcase(tags)
endelse


if not keyword_set(format) then begin
  tgi = array_union(tg,tag_names(str))
  title = ''
  format = '('
  for j=0,n_elements(tgi)-1 do begin
     dt = data_type(str[0].(tgi[j]),n_elements=nd)
     sz = sizes[dt]
     form = forms2[dt]
     if form eq 'x' then begin
        dprint,'Tagname: '+tg[j]+' Ignored.'
        tg[j] = ''
        continue
     endif
     taglen = strlen(tg[j])
     if nd gt 1 then taglen = taglen+2+strlen(strtrim(nd,2))
     if form eq 'a' then sz = max(strlen(str.(tgi[j])))
     if form eq 'i' then sz = max(strlen(strtrim(minmax(str.(tgi[j])),2 ) ) )
     sz = sz > taglen
     if nd eq 1 then jtit = string(/print,tg[j],f='(a'+strtrim(sz,2)+'," ")')  $
     else jtit = string(/print,tg[j]+'['+strtrim(indgen(nd),2)+']',f='(20(a'+strtrim(sz)+'," "))')
     title = title+jtit
     if form eq 'g' then form=strcompress(/remove,string('g',sz,'.',sz-6)) $
     else      form = forms2[dt]+strtrim(sz,2)
     format = format + strtrim(nd,2)+'(' + form + '," "),'
  endfor
  format = format+'" ")'
  printf,lun,title
;  print,format
endif

if 0 then begin
  extract_tags,s,str[0],tags=tg
  title = ''
  format = '('
  tn = tag_names(s)
  for j=0,n_tags(s)-1 do begin
     dt = data_type(s.(j),n_elements=nd)
     sz = sizes[dt]
     if nd eq 1 then jtit = string(/print,tn[j],f='(a'+strtrim(sz,2)+'," ")')  $
     else jtit = string(/print,tn[j]+'['+strtrim(indgen(nd),2)+']',f='(20(a'+strtrim(sz)+'," "))')
     title = title+jtit
     format = format + strtrim(nd,2)+'(' + forms[dt] + '," "),'
  endfor
  format = format+'" ")'
  printf,lun,title
;  print,format
endif

tg = tg[where(tg)]
for i=0L,n_elements(str)-1 do begin
  extract_tags,s,str[i],tags=tg
  printf,lun,s,format=format
endfor

if size(/type,file) eq 7 then free_lun,lun

end
