;+
; NAME: sppeva_load
; 
; PURPOSE: to load SPP data (as listed in a parametet-set config file)  
;
; INPUT:
;   parameterSet: The filename of the parameterSet. e.g.,"01_wi_basic"
;   
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/sppeva/source/data/sppeva_load.pro $
;-
PRO sppeva_load, parameterSet = parameterSet, no_gui=no_gui, force=force, $
  paramlist=paramlist, get_paramlist=get_paramlist
  compile_opt idl2
  clock=tic('sppeva_load')
  if undefined(parameterSet) then parameterSet = !SPPEVA.COM.PARAMETERSET
  
  ;-----------------
  ; parameter list
  ;-----------------
  paramlist = sppeva_data_paramSetRead(parameterSet)
  if keyword_set(get_paramlist) then return
  
  imax = n_elements(paramlist)
  cparam = imax
  if not keyword_set(no_gui) then begin
    if cparam ge 17 then begin
      rst = dialog_message('Total of '+strtrim(string(cparam),2)+' parameters. Still plot?',/question,/center)
    endif else rst = 'Yes'
    if rst eq 'No' then return
  endif
  
  ;-----------------
  ; timespan
  ;-----------------
  tr = time_double(!SPPEVA.COM.STRTR)
  timespan,tr[0], tr[1]-tr[0], /seconds 
 
  ;-------------------
  ; PREP PROGRESS BAR
  ;-------------------
  if ~keyword_set(no_gui) then begin
    progressbar = Obj_New('progressbar', background='white', Text='Loading SPP data ..... 0 %')
    progressbar -> Start
  endif

  
  ;-----------------
  ; MAIN LOOP
  ;-----------------
  perror = [-1]
  c=0
  for i=0,imax-1 do begin; for each parameter
    
    ;----------------
    ; Progress bar
    ;----------------
    prg = 100.0*float(c)/float(cparam)
    sprg = 'Loading data ....... '+string(prg,format='(I2)')+' %'
    if ~keyword_set(no_gui) then begin
      if progressbar->CheckCancel() then begin
        ok = Dialog_Message('User cancelled operation.',/center) ; Other cleanup, etc. here.
        break
      endif else progressbar -> Update, prg, Text=sprg
    endif
    
    ;--------------------
    ; Check if pre-loaded or not.
    ;--------------------
    slen = strlen(paramlist[i])
    last_two_char = strmid(paramlist[i],slen-2,1000)
    if strmatch(last_two_char,'*_*') then begin
      parambody = strmid(paramlist[i],0,slen-2)
      TO_BE_REFORMED = 1
    endif else begin
      parambody = paramlist[i]
      TO_BE_REFORMED = 0
    endelse
    tn=tnames(parambody,ct)
    PRELOADED = (ct gt 0)
    if keyword_set(force) then PRELOADED = 0

    ;----------------------
    ; LOAD
    ;----------------------
    pcode = -1
    if not PRELOADED then begin
      mission = strmid(paramlist[i],0,2)
      case mission of
        'wi': pcode=sppeva_load_wind(paramlist[i], perror)
        'st': 
        'sp': pcode=sppeva_load_spp(paramlist[i], perror)
        'ps': pcode=sppeva_load_spp(paramlist[i], perror)
        else:
      endcase
    endif; if not PRELOADED
    if pcode ne -1 then begin
      perror = [perror,pcode]
    endif
    
    ;----------------------
    ; REFORMAT
    ;----------------------
    if TO_BE_REFORMED then begin 
      sppeva_load_reformat, parambody, last_two_char
    endif
    
    c+= 1
  endfor
  
  ;--------------
  ; FINALIZE
  ;--------------
  if ~keyword_set(no_gui) then progressbar -> Destroy
  
  toc, clock
END
