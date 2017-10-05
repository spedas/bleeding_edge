FUNCTION mms_bss_replace, s, idx
  compile_opt idl2
  if idx[0] lt 0 then begin
    return, -1
  endif
  snew = {$
   CHANGESTATUS: s.CHANGESTATUS[idx], $
   CREATETIME: s.CREATETIME[idx], $
   DATASEGMENTID: s.DATASEGMENTID[idx], $
   DISCUSSION: s.DISCUSSION[idx], $
   FINISHTIME: s.FINISHTIME[idx], $
   FOM: s.FOM[idx], $
   INPLAYLIST: s.INPLAYLIST[idx], $
   ISPENDING: s.ISPENDING[idx], $
   NBUFFS: total(s.SEGLENGTHS[idx]), $
   NUMEVALCYCLES: s.NUMEVALCYCLES[idx], $
   PARAMETERSETID: s.PARAMETERSETID[idx], $
   SEGLENGTHS: s.SEGLENGTHS[idx], $
   SOURCEID: s.SOURCEID[idx], $
   START: s.START[idx], $
   STATUS: s.STATUS[idx], $
   STOP: s.STOP[idx],$
   UNIX_CREATETIME: s.UNIX_CREATETIME[idx],$
   UNIX_FINISHTIME: s.UNIX_FINISHTIME[idx]}
  return, snew
END
