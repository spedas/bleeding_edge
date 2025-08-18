;+
;FUNCTION mvn_pfp_file_next_revision(filename,ndigits, [extension=extension])
;Returns the filename with the next revision number
;Warning: unpredictable results at rollover.
;-
function  mvn_pfp_file_next_revision, filename,ndigits, extension=extension

  if not keyword_set(ndigits) then ndigits = 2
  if not keyword_set(extension) then extension = '.'
  nfilename = filename
  n = n_elements(filename)
  for i=0l,n-1 do begin
    f = filename[i]
    pos = strpos(/reverse_search,f,extension)
    if pos lt ndigits then continue
    revstr = strmid(f,pos-ndigits,ndigits)
    ;  printdat,revstr
    revnum = strpos(revstr,'?') lt 0 ? fix(revstr) : 0
    format =  string(format='("(i0",i1,")")',ndigits)
    nextrev = string(format=format,revnum+1)
    strput, f,nextrev,pos-ndigits
    nfilename[i] = f
  endfor
  if n eq 1 then nfilename=nfilename[0]
  return,nfilename
end


