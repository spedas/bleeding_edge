;+
; NAME: mms_bss_table
;
; PURPOSE: 
;   To create a table of segments in the back-structure
;   organized by categories. 'bss' stands for 'burst segment status'
;   which is the official name of the back-structure.
;
; USAGE:
;   With no keyword, this program diplays a table of segments from the
;   entire mission. Use the keywords to select certain types of segments.
;
; EXAMPLE:
;   To make a table of PENDING segmnents,
;   
;     MMS> mms_bss_table, /isPending
;     
;   Pending segments are actually non-FINISHED segments (if bad segments
;   are removed). So, the same result can be obtained by
;   
;     MMS> mms_bss_table, exclude='FINISHED'
;   
; KEYWORDS:
;   BSS: back-structure created by mms_bss_query
;   TRANGE: narrow the time range. It can be in either string or double.
;   OVERWRITTEN: Set this keyword to show overwritten segments only.
;   BAD:         Set this keyword to show bad segments only. Bad segments mean
;                segments with TRIMMED, SUBSUMED, DELETED statuses. Some of
;                the bad segments have infinite number of buffers. In such
;                cases, 'Nbuffs' and 'min' will be displayed as *******.
;   CONSOLE: If set to 1 (DEFAULT), output in console
;   JSON: If set to 1, output in a json file
;   DIR: directory for the json output
;   _EXTRA: See 'mms_bss_query' for other optional keywords
;
; CREATED BY: Mitsuo Oka  Aug 2015
;
; $LastChangedBy: moka $
; $LastChangedDate: 2016-10-06 15:43:35 -0700 (Thu, 06 Oct 2016) $
; $LastChangedRevision: 22058 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/bss/mms_bss_table.pro $
;-
PRO mms_bss_table, bss=bss, trange=trange, bad=bad, overwritten=overwritten, $
  console=console, json=json, dir=dir, _extra=_extra
  compile_opt idl2
  
  clock=tic('mms_bss_table')
  mms_init
  if n_elements(console) eq 0 then console = 1
  if n_elements(json) eq 0 then json = 0
  if undefined(dir) then dir = '/Volumes/moka/public_html/eva/'
  dir = spd_addslash(dir)
  
  ;----------------
  ; CATCH
  ;----------------
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    message, /reset
    return
  endif
  
  ;----------------
  ; TIME
  ;----------------
  tnow = systime(/utc,/seconds)
  tlaunch = time_double('2015-03-12/22:44')
  t3m = tnow - 180.d0*86400.d0; 180 days
  if n_elements(trange) eq 2 then begin
    tr = timerange(trange)
  endif else begin
    tr = [t3m,tnow]
    ;tr = [tlaunch,tnow]
    trange = time_string(tr)
  endelse
  
  ;----------------
  ; LOAD DATA
  ;----------------
  if n_elements(bss) eq 0 then begin
  
    if keyword_set(overwritten) then begin
      a = mms_bss_query(exclude='INCOMPLETE',_extra=_extra)
      bss = mms_bss_query(bss=a, status='DEMOTED DERELICT', _extra=_extra)
    endif
  
    if keyword_set(bad) then begin
      a = mms_bss_load(); load all segments including bad ones
      bss = mms_bss_query(bss=a, status='trimmed subsumed deleted obsolete')
    endif
  
    if n_tags(bss) eq 0 then begin
      bss = mms_bss_query(trange=trange,_extra=_extra)
    endif
  endif
  
  ;------------------
  ; COUNT BY CATEGORY
  ;------------------
  pmax = 6
  title = 'Category '+strtrim(string(sindgen(pmax)),2)
  title[pmax-1] = 'Total     '
  wNsegs = lindgen(pmax)
  wNbuffs = lindgen(pmax)
  wTmin = dindgen(pmax)
  wstrTlast = sindgen(pmax)
  wSegID  = lindgen(pmax)
  for p=0,pmax-1 do begin
    b = mms_bss_query(bss=bss,cat=p)
    ct = (n_tags(b) eq 0) ? 0: n_elements(b.FOM)
    if ct eq 0 then begin
      wNsegs[p] = 0L
      wNbuffs[p] = 0L
      wTmin[p] = 0.d0
      wstrTlast[p] = ''
      wSegID[p] = 0L
    endif else begin
      wNsegs[p] = ct; total number of segments
      wNbuffs[p] = total(b.SEGLENGTHS); total number of buffers
      wTmin[p] = double(wNbuffs[p])/6.d0; total number of minutes
      wstrTlast[p] = time_string(min(b.START,nmin))
      wSegID[p] = b.DATASEGMENTID[nmin]
    endelse
  endfor

  ;------------------
  ; OUTPUT (CONSOLE)
  ;------------------
  if console then begin
    print,' As of '+time_string(systime(/utc,/seconds))+' UTC'
    print,' -------------------------------------------------------------------'
    print,'           ,   Nsegs,  Nbuffs,   [min],      %,  SegID, Oldest segment'
    print,' -------------------------------------------------------------------'
    for p=0,pmax-1 do begin
      ttlPrcnt = 100.*wTmin[p]/wTmin[pmax-1]
      print, title[p],wNsegs[p],wNbuffs[p],wTmin[p],ttlPrcnt, wSegID[p], wstrTlast[p], format='(A11," ",I8," ",I8," ",I8," ",F7.1," ",I12," ",A20)'
    endfor
  endif; if console

  

  ;------------------
  ; OUTPUT (JSON)
  ;------------------
  if json then begin
    if !VERSION.RELEASE lt 8.2 then begin
      print,'JSON SERIALIZE not supported before IDL 8.2'
      return
    endif
    
    ; json_serialize
    jarr = strarr(pmax)
    for p=0,pmax-1 do begin
      strNsegs = strtrim(string(wNsegs[p]),2)
      strNbuffs = strtrim(string(wNbuffs[p]),2)
      strTminu = string(wTmin[p],format='(I6)')
      strPrcnt = string(100.*wTmin[p]/wTmin[pmax-1], format='(F5.1)')
      strSegID = strtrim(string(wSegID[p]),2)
      if wSegID[p] eq 0 then strSegID = 'N/A'
      strct = {title:title[p],Nsegs:strNsegs, Nbuffs:strNbuffs, Tminu:strTminu, $
        ttlPrcnt: strPrcnt, strTlast:wstrTlast[p], strSegID:strSegID}
      jarr[p] = json_serialize(strct)
    endfor
        
    ; output
    fname  = 'mms_bss_table.json'
    if n_elements(dir) eq 1 then fname = dir + fname
    openw,nf,fname,/get_lun ; open as a new file
    printf,nf,'['
    for p=0,pmax-2 do begin
      printf, nf, jarr[p]+','
    endfor
    printf,nf,jarr[pmax-1] ; no comma for the last item
    printf,nf,']'
    free_lun, nf
  endif; if json
  toc, clock
END 