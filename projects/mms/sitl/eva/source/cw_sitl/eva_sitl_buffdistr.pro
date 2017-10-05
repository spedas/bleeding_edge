FUNCTION eva_sitl_buffdistr, console=console, msg=msg
  compile_opt idl2
  

  ;------------------
  ; LOAD FOM
  ;------------------
  
  tn=tnames('mms_stlm_fomstr',n)
  if n ne 1 then return, 'no FOMstr found'
  
  get_data,'mms_stlm_fomstr',data=D,dl=dl,lim=lim
  s = lim.unix_FOMstr_mod

  ;------------------
  ; PREP TABLE
  ;------------------
  pmax = 6
  title = 'Category '+strtrim(string(sindgen(pmax)),2)
  title[pmax-1] = 'Total     '
  wNsegs = lonarr(pmax)
  wNbuffs = lonarr(pmax)
  wTmin = dblarr(pmax)
  wstrTlast = strarr(pmax)
  val = mms_load_fom_validation()

  fomrng = fltarr(pmax,2)
  fomrng[0,0] = float(val.TYPE1_RANGE[1]+1L) & fomrng[0,1] = 256L
  fomrng[1,0] = float(val.TYPE1_RANGE[0])    & fomrng[1,1] = float(val.TYPE1_RANGE[1]+1L)
  fomrng[2,0] = float(val.TYPE2_RANGE[0])    & fomrng[2,1] = float(val.TYPE2_RANGE[1]+1L)
  fomrng[3,0] = float(val.TYPE3_RANGE[0])    & fomrng[3,1] = float(val.TYPE3_RANGE[1]+1L)
  fomrng[4,0] = float(val.TYPE4_RANGE[0])    & fomrng[4,1] = float(val.TYPE4_RANGE[1]+1L)
  fomrng[5,0] = float(val.TYPE4_RANGE[0])    & fomrng[5,1] = 256L

  ;------------------
  ; MAIN LOOP
  ;------------------
  nmax = s.NSEGS
  ct = 0
  for n=0,nmax-1 do begin; for each segment
    for p=0,pmax-1 do begin; scan each category
      if (fomrng[p,0] le s.FOM[n]) and (s.FOM[n] lt fomrng[p,1]) then begin
        wNsegs[p] += 1
        wNbuffs[p] += s.SEGLENGTHS[n]
        wTmin[p] += double(s.SEGLENGTHS[n])/6.d0
        ct += 1
      endif
    endfor; scan each cat
  endfor; for each segment

  ;------------------
  ; OUTPUT (CONSOLE)
  ;------------------
  if keyword_set(console) then begin
    print,' Current SITL selections:'
    print,' -------------------------------------------------------------------'
    print,'           ,   Nsegs,  Nbuffs,   [min],      %'
    print,' -------------------------------------------------------------------'
    for p=0,pmax-1 do begin
      ttlPrcnt = 100.*wTmin[p]/wTmin[pmax-1]
      print, title[p],wNsegs[p],wNbuffs[p],wTmin[p],ttlPrcnt, format='(A11," ",I8," ",I8," ",I8," ",F7.1)'
    endfor
    return,'output in console'
  endif; if console
  
  ;------------------
  ; OUTPUT (msg)
  ;------------------
  if keyword_set(msg) then begin
    msg = '================================================='
    msg = [msg, 'Summary of selections:']
    msg = [msg, '=================================================']
    msg = [msg, '              Nsegs,  Nbuffs,   [min],      %']

    for p=0,pmax-1 do begin
      ttlPrcnt = 100.*wTmin[p]/wTmin[pmax-1]
      str =  string(title[p],wNsegs[p],wNbuffs[p],wTmin[p],ttlPrcnt, format='(A10," ",I8," ",I8," ",I8," ",F7.1)')
      msg = [msg,str]
    endfor
    return, msg
  endif; if msg
END
