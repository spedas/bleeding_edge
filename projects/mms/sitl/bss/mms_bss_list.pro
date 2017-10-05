;+
; NAME: mms_bss_list
;
; PURPOSE: 
;   To generate a list of segments from the back-structure.
;   'bss' stands for 'burst segment status' which is the official 
;   name of the back-structure.
;
; USAGE: 
;   If you call this procedure with no keyword, then you will get
;   a list of all segments from the entire mission (but 'bad' segments 
;   excluded). Please use keywords to narrow down the list.
; 
; EXAMPLES:
;   
;   (1) A list of segments during a specific time range.
;
;       MMS> mms_bss_list,trange=['2015-08-15/12:00','2015-08-15/16:00']
;   
;   (2) A list of 'overwritten' segments
;
;       MMS> mms_bss_list,/overwritten
;   
; KEYWORDS:
;   BSS: back-structure created by mms_bss_query
;   OVERWRITTEN: Set this keyword to show overwritten segments only.
;   BAD:         Set this keyword to show bad segments only. Bad segments mean
;                segments with TRIMMED, SUBSUMED, DELETED statuses.
;   _EXTRA: See 'mms_bss_query' for other optional keywords 
;
; CREATED BY: Mitsuo Oka  Aug 2015
;
; $LastChangedBy: moka $
; $LastChangedDate: 2015-09-15 06:24:47 -0700 (Tue, 15 Sep 2015) $
; $LastChangedRevision: 18796 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/bss/mms_bss_list.pro $
;-
PRO mms_bss_list, bss=bss, overwritten=overwritten, bad=bad, _extra=_extra
  compile_opt idl2
  
  mms_init
  
  ;----------------
  ; LOAD DATA
  ;----------------
  if n_elements(bss) eq 0 then begin
  
    if keyword_set(overwritten) then begin
      a = mms_bss_query(exclude='INCOMPLETE',_extra=_extra)
      bss = mms_bss_query(bss=a, status='DEMOTED DERELICT', _extra=_extra)
    endif
  
    if keyword_set(bad) then begin
      a = mms_bss_load(_extra=_extra); load all segments including bad ones
      bss = mms_bss_query(bss=a, status='trimmed subsumed deleted obsolete')
    endif
  
    if n_tags(bss) eq 0 then begin
      bss = mms_bss_query(trange=trange,_extra=_extra)
    endif
  endif

  ;------------------
  ; OUTPUT
  ;------------------
  if n_tags(bss) eq 0 then begin
    print, ' 0 segment found'
    return
  endif
  nmax = n_elements(bss.FOM)
  print, ' --------------------------------------------------------------------'
  print, '   ID   START_TIME        LENGTH   FOM  STATUS, SOURCEID, DISCUSSION
  print, ' --------------------------------------------------------------------'
  for n=0,nmax-1 do begin
    print, bss.DATASEGMENTID[n],time_string(bss.START[n]),bss.SEGLENGTHS[n],$
      bss.FOM[n], bss.STATUS[n], bss.SOURCEID[n],bss.DISCUSSION[n],$
      format='(I7,A20,",",I3,",",F6.1,", ",A,", ",A,", ",A)'
  endfor
  print, nmax, ' segments found'
END
