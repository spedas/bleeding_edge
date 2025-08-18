;+
;
;FUNCTION: SPPEVA_SELECT
;PURPOSE:  To select an entire period of "encounter" for burst selection.
;
;INPUT:
;  file_in : (Optional) A name of CSV file that contains a played-back time intervals.
;            These time intervals will be skipped in the selection. If this file is not
;            provided, then this script just returns the entire period of encounter.
;  file_out: (Optional) The name of the output file. If omitted, a suffix "_full"
;                       will be added to the input file name.
;  mode    :  (Optional) Set 'FLD' or 'SWP'
;  discussion: (Optional) Discussion string for the orbit
;  fom     :  (Optional) FOM value for the orbit (Default: 20)
;
;CREATED BY:   Mitsuo Oka
;
; $LastChangedBy: moka $
; $LastChangedDate: 2020-11-23 14:46:41 -0800 (Mon, 23 Nov 2020) $
; $LastChangedRevision: 29383 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/sppeva/source/selection/sppeva_select.pro $
;
;-
PRO sppeva_select, orbit, file_in=file_in, file_out=file_out, fom=fom, mode=mode, discussion=discussion
  compile_opt idl2

  ;---------------------
  ; INIT
  ;---------------------
  sppeva_init
  if undefined(orbit) then begin
    result = dialog_message('Please specify an orbit.',/center)
    return
  endif
  if undefined(fom) then fom=20.0
  if undefined(discussion) then discussion='Full '+strtrim(string(orbit),2)+' Encounter'
  if undefined(mode) then mode = 'FLD'
  var = 'spp_'+mode+'_fomstr'
  filename = ProgramRootDir()+'spp.mde.txt'
  filename = '/Users/moka/WorkspaceIDL/spdsoft/projects/SPP/COMMON/sppeva/source/data/spp.mde.txt'
  result = file_test(filename)
  if result eq 0 then msg=dialog_message('spp.mde.txt not found',/center)

  ;---------------------
  ; OUTPUT FILE
  ;---------------------
  if undefined(file_out) then begin
    if undefined(file_in) then begin
      file_out = var+'_orbit'+strtrim(string(orbit),2)
    endif else begin
      if strmatch(file_in,'*.csv') then begin; If .csv extension does exist
        file_in_temp = strmid(file_in,0,max(strsplit(file_in,'.')-1)); then remove it.
      endif
      file_out = file_in_temp+'_full'
    endelse
    file_out += '.csv'
  endif else begin
    if not strmatch(file_out,'*.csv') then begin
      file_out += '.csv'
    endif
  endelse
  


  ;---------------------
  ; LOAD ORBIT SCHEDULE
  ;---------------------
  s = sppeva_load_mde()
  nmax = n_elements(s)
  stime = ''
  etime = ''
  label = ''
  ct = 0
  CurrentOrbit = 0
  for n = 0, nmax-1 do begin; for each line
    
    if(strpos(s[n],'Orbit') eq 0) then CurrentOrbit = long(strmid(s[n],6,1000))
    
    if( (CurrentOrbit eq orbit) and (strpos(s[n],'Solar Encounter Start') gt 0)) then begin
      str = strsplit(s[n],' ', count=count,/extract)
      stime = time_string(time_double(str[0]+' '+str[1],tformat='MM-DD-YYYY hh:mm:ss'))
    endif

    if( (CurrentOrbit eq orbit) and (strpos(s[n],'Solar Encounter Stop') gt 0)) then begin
      str = strsplit(s[n],' ', count=count,/extract)
      etime = time_string(time_double(str[0]+' '+str[1],tformat='MM-DD-YYYY hh:mm:ss'))
    endif
    
  endfor

  ;---------------------
  ; CREATE STRUCTURE
  ;---------------------
  s = {NSEGS:1, $
    SOURCEID:!SPPEVA.USER.ID, $
    START: time_double(stime), $
    STOP: time_double(etime), $
    FOM: fom, $
    DISCUSSION: discussion}
  
  ;-------------------------------------
  ; UPDATED STRUCTURE (from playback)
  ;-------------------------------------
  if ~undefined(file_in) then begin
    if not strmatch(file_in,'*.csv') then begin
      file_in += '.csv'
    endif
    sppeva_sitl_csv2tplot, file_in, var=var, status=status, suffix='_playback'
    get_data,var+'_playback',data=D,dl=dl,lim=lim
    s_playback = dl.FOMSTR
    nmax       = s_playback.NSEGS
    
    ;----
    pstart      = s.START
    pstop       = s_playback.START[0]
    pfom        = s.FOM
    pdiscussion = s.DISCUSSION
    psourceid   = s.SOURCEID
    ;----
    for n=0,nmax-2 do begin
      pstart      = [pstart, s_playback.STOP[n]]
      pstop       = [pstop,  s_playback.START[n+1]]
      pfom        = [pfom, s.FOM]
      pdiscussion = [pdiscussion, s.DISCUSSION]
      psourceid   = [psourceid, s.SOURCEID]
    endfor
    ;----
    pstart = [pstart, s_playback.STOP[nmax-1]]
    pstop  = [pstop, s.STOP]
    pfom        = [pfom, s.FOM]
    pdiscussion = [pdiscussion, s.DISCUSSION]
    psourceid   = [psourceid, s.SOURCEID]
    
    s = {NSEGS: nmax+1, $
      SOURCEID:psourceid, $
      START: pstart, $
      STOP: pstop, $
      FOM: pfom, $
      DISCUSSION: pdiscussion}
  endif
  
  ;-------------------------------------
  ; STORE STRUCTURE
  ;-------------------------------------
  sppeva_sitl_strct2tplot, s, var
  
  ;---------------------
  ; GET BLOCK DATA
  ;---------------------
  get_data,var,data=D,dl=dl,lim=lim
  tstart = min(dl.FOMSTR.START)-86400.d0
  tstop  = max(dl.FOMSTR.STOP)+86400.d0
  sppeva_get_fld,'f1_100bps',trange=[tstart,tstop]


  ;---------------------
  ; WRITE CSV
  ;---------------------
  sppeva_sitl_tplot2csv, var, filename=file_out, msg=msg, error=error, auto=auto

END
