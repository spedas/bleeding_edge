; This function removes bad segments from the back-structure loaded by
; 'mms_bss_load'
FUNCTION mms_bss_cleanup, s, withdeleted=withdeleted, structure=structure, $
  loud=loud
  compile_opt idl2

  ;remove error segments
  idx = where(s.SEGLENGTHS ne 429496728L,ct,comp=nidx)
  idx0 = idx; NON-ERATIC
  nidx0 = nidx; ERATIC
  if keyword_set(loud) then begin
    nmax = n_elements(nidx0)
    print,'--- ERROR SEGMENT (',nmax,') ---'
    if nmax gt 0 then begin
      for n=0,nmax-1 do begin
        print, s.DATASEGMENTID[nidx0[n]], ': ', s.STATUS[nidx0[n]], ', SEGLENGTHS=',s.SEGLENGTHS[nidx0[n]]
      endfor
    endif
  endif
  
  ;remove TRIMMED segments
  idx = where(~strmatch(strlowcase(s.STATUS[idx0]),'*trimmed*'),ct,comp=nidx)
  idx1 = idx0[idx]; NOT-TRIMMED segments
  nidx1 = idx0[nidx]; TRIMMED segments
  if keyword_set(loud) then begin
    nmax = n_elements(nidx1)
    print,'--- TRIMMED SEGMENT (',nmax,') ---'
    if nmax gt 0 then begin
      for n=0,nmax-1 do begin
        print, s.DATASEGMENTID[nidx1[n]], ': ', s.STATUS[nidx1[n]], ', SEGLENGTHS=',s.SEGLENGTHS[nidx1[n]]
      endfor
    endif
  endif

  ;remove SUBSUMED segments
  idx = where(~strmatch(strlowcase(s.STATUS[idx1]),'*subsumed*'), ct, comp=nidx)
  idx2 = idx1[idx]; NOT-SUBSUMED segments
  nidx2 = idx1[nidx]; SUBSUMED segments
  if keyword_set(loud) then begin
    nmax = n_elements(nidx2)
    print,'--- SUBSUMED SEGMENT (',nmax,') ---'
    if nmax gt 0 then begin
      for n=0,nmax-1 do begin
        print, s.DATASEGMENTID[nidx2[n]], ': ', s.STATUS[nidx2[n]], ', SEGLENGTHS=',s.SEGLENGTHS[nidx2[n]]
      endfor
    endif
  endif
  
  ;remove DELETED segments
  if keyword_set(withdeleted) then begin
    idx3 = idx2
    nidx3 = nidx2
  endif else begin
    idx = where(~strmatch(strlowcase(s.STATUS[idx2]),'*deleted*'), ct, comp=nidx)
    idx3 = idx2[idx]
    nidx3 = idx2[nidx]
    if keyword_set(loud) then begin
      nmax = n_elements(nidx3)
      print,'--- DELETED SEGMENT (',nmax,') ---'
      if nmax gt 0 then begin
        for n=0,nmax-1 do begin
          print, s.DATASEGMENTID[nidx3[n]], ': ', s.STATUS[nidx3[n]], ', SEGLENGTHS=',s.SEGLENGTHS[nidx3[n]]
        endfor
      endif
    endif
  endelse

  ;remove OBSOLETE segments
  idx = where(~strmatch(strlowcase(s.STATUS[idx3]),'*obsolete*'), ct, comp=nidx)
  idx4 = idx3[idx]; NOT-OBSOLETE segments
  nidx4 = idx3[nidx]; OBSOLETE segments
  if keyword_set(loud) then begin
    nmax = n_elements(nidx4)
    print,'--- SUBSUMED SEGMENT (',nmax,') ---'
    if nmax gt 0 then begin
      for n=0,nmax-1 do begin
        print, s.DATASEGMENTID[nidx4[n]], ': ', s.STATUS[nidx4[n]], ', SEGLENGTHS=',s.SEGLENGTHS[nidx4[n]]
      endfor
    endif
  endif
  
  result = keyword_set(structure) ? mms_bss_replace(s,idx4) : idx4
  return, result
END
