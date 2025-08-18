; NAME: eva_sitl_strct_read
; PURPOSE: Read a FOM or BAK structure and generate a tplot data stucture, i.e. D = {x:fom_x, y:fom_y}
; INPUT: 
;   s: stucture (either FOMstr or BAKstr)
;   tstart: the start time
;   
; $LastChangedBy: moka $
; $LastChangedDate: 2015-07-13 13:25:19 -0700 (Mon, 13 Jul 2015) $
; $LastChangedRevision: 18107 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/cw_sitl/eva_sitl_strct_read.pro $
Function eva_sitl_strct_read, s, tstart, $
  isPending=isPending, inPlaylist=inPlaylist, status=status, quiet=quiet
  compile_opt idl2
  
  if n_elements(status) eq 0 then begin 
    status = '' 
  endif else begin
    status = strlowcase(status)
    if strmatch(status,'*overwritten*') then status = 'demoted'
  endelse
  
  
  ; determine FOMStr or BAKStr
  tn = tag_names(s)
  idx = where(strpos(tn,'FOMSLOPE') ge 0, ct); ct > 0 if FOMStr
  typeFOM = (ct gt 0)  
  if typeFOM then NSegs = s.Nsegs else Nsegs = n_elements(s.FOM)
  
  fom_x = [tstart]
  fom_y = 0.0
  if typeFOM then begin
    ; The last cycle (buffer) number of the last segment should not be equal to NUMCYCLES
    if s.STOP[Nsegs-1] ge s.NUMCYCLES then message,'Something is wrong'
    for N=0,Nsegs-1 do begin
      ss = s.TIMESTAMPS[s.START[N]]; segment start time
      dtlast = s.TIMESTAMPS[s.NUMCYCLES-1L]-s.TIMESTAMPS[s.NUMCYCLES-2L]
      se = (s.STOP[N] ge s.NUMCYCLES-1L) ? s.TIMESTAMPS[s.NUMCYCLES-1L]+dtlast : s.TIMESTAMPS[s.STOP[N]+1L]
      fom_x = [fom_x, ss, ss, se, se]
      fom_y = [fom_y, 0., s.FOM[N], s.FOM[N], 0.]
    endfor 
  endif else begin

    ;---------------------
    ; HEADER (in console)
    ;---------------------    
    if (not keyword_set(quiet)) then begin
      title = strupcase(status)
      if keyword_set(isPending) then title = 'PENDING'
      if keyword_set(inPlaylist) then title = 'IN-PLAYLIST'
      str1 = ''
      print, 'EVA:  '
      print, 'EVA:----- List of '+title+' segments -----'
      if (strmatch(status,'complete') or strmatch(status,'finished')) then str1 = ', finish time        ' 
      print, 'EVA: segID, start time         , FOM    '+str1+', sourceID'
    endif
    
    ;-------------------
    ; SCAN each segment
    ;-------------------
    ct = 0
    for N=0,Nsegs-1 do begin
      OK = 1
      if keyword_set(isPending) then OK = s.ISPENDING[N]
      if keyword_set(inPlaylist)then OK = s.INPLAYLIST[N]
      if strlen(status) gt 1    then OK = (strpos(strlowcase(s.STATUS[N]),status) ge 0)
      if (strpos(strlowcase(s.STATUS[N]),'incomplete') ge 0) and strmatch(status,'complete') then OK = 0
      
      if OK then begin
        
        ; get the data
        fv = (strpos(strlowcase(s.STATUS[N]),'deleted') ge 0) ? 0 : s.FOM[N]
        if strmatch(status,'deleted') then fv = s.FOM[N]
        ss = double(s.START[N])
        se = double(s.STOP[N]+10.d0)
        fom_x = [fom_x, ss, ss, se, se]
        fom_y = [fom_y, 0., fv, fv, 0.]
        
        ; output in console
        if not keyword_set(quiet) then begin
          strN = string(N, format='(I5)'); segment number
          strF = string(s.FOM[N], format='(F7.3)'); FOM value
          strout = 'EVA: '+strN+': '+time_string(ss)+', '+strF
          if strlen(str1) gt 0 then strout += ', '+s.FINISHTIME[N]
          if strlen(status) eq 0 then begin
            print, strout+', '+s.SOURCEID[N]
          endif else begin
            print, strout+', '+s.STATUS[N]
          endelse
        endif
        
        ct += 1
      endif
    endfor
    if (ct eq 0) and (~keyword_set(quiet)) then begin
      print, 'EVA: ... '+strupcase(status)+' segment not found!'
    endif
  endelse
  
  D = {x:fom_x, y:fom_y}
  
  return, D
End
