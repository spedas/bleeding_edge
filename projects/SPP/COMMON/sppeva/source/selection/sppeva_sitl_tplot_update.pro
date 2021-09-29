PRO sppeva_sitl_tplot_update, segSelect, var
  compile_opt idl2
  
  ;------------------
  ; OLD FOMSTR
  ;------------------
  
  get_data, var, data=D, lim=lim, dl=dl
  s = dl.FOMSTR
  ;s = sppeva_sitl_strct_update(segSelect, dl.FOMSTR)
  
  ;------------------
  ; VALIDATION
  ;------------------
  ;tfom = s.TR
  tfom = time_double(!SPPEVA.COM.STRTR)
  r = segment_overlap([segSelect.TS,segSelect.TE],tfom)

  case r of
    -2: message,'Out of range.'
    -1: segSelect.TS = tfom[0]
    1: segSelect.TE = tfom[1]
    2: message,'Out of range.'
    3: message,'Segment size way too big.'
    4: message,'Segment size way too big.'
    else:; 0 --> OK
  endcase

  ;------------------------------------------------------------
  ; NEW FOMSTR
  ;------------------------------------------------------------

  newDISCUSSION = ''
  newSOURCEID = ''
  newSTART = 0.d0
  newSTOP  = 0.d0
  newFOM   = 0.
  ADD = 1L

  ; Scan all pre-existing segments and copy/split as needed.
  if s.Nsegs ge 1 then begin
    for N=0, s.Nsegs-1 do begin
      ; Each pre-existing segment is compared to the User's new/modified segment
      rr = segment_overlap([s.START[N], s.STOP[N]],[segSelect.TS, segSelect.TE])
      case abs(rr) of
        1: begin; partial overlap --> split
          newDISCUSSION = [newDISCUSSION, s.DISCUSSION[N]]
          newSOURCEID   = [newSOURCEID, s.SOURCEID[N]]
          newFOM        = [newFOM,   s.FOM[N]]
          if rr eq -1 then begin
            newSTART = [newSTART, s.START[N]]
            newSTOP  = [newSTOP, segSelect.TS]
          endif else begin
            newSTART = [newSTART, segSelect.TE]
            newSTOP  = [newSTOP, s.STOP[N]]
          endelse
        end
        2: begin; no overlap --> preserve this segment
          newDISCUSSION = [newDISCUSSION, s.DISCUSSION[N]]
          newSOURCEID   = [newSOURCEID, s.SOURCEID[N]]
          newSTART      = [newSTART, s.START[N]]
          newSTOP       = [newSTOP,  s.STOP[N]]
          newFOM        = [newFOM,   s.FOM[N]]
        end
;        3:; exactly the same as segSelect --> ignore (will be added anyway)
        4: begin; larger than segSelect -->
          if s.FOM[N] eq segSelect.FOM then begin; if already high FOM than segSelect
;            ADD = 0; ignore the new selection, segSelect
;            newDISCUSSION = [newDISCUSSION, s.DISCUSSION[N]]
;            newSOURCEID   = [newSOURCEID, s.SOURCEID[N]]
;            newSTART      = [newSTART, s.START[N]]
;            newSTOP       = [newSTOP,  s.STOP[N]]
;            newFOM        = [newFOM,   s.FOM[N]]
          endif else begin; split
            ; The leading part
            newDISCUSSION = [newDISCUSSION, s.DISCUSSION[N]]
            newSOURCEID   = [newSOURCEID, s.SOURCEID[N]]
            newSTART      = [newSTART, s.START[N]]
            newSTOP       = [newSTOP,  segSelect.TS]
            newFOM        = [newFOM,   s.FOM[N]]
            ; the trailing part
            newDISCUSSION = [newDISCUSSION, s.DISCUSSION[N]]
            newSOURCEID   = [newSOURCEID, s.SOURCEID[N]]
            newSTART      = [newSTART, segSelect.TE]
            newSTOP       = [newSTOP,  s.STOP[N]]
            newFOM        = [newFOM,   s.FOM[N]]
          endelse
        end
        else:; contained in segSelect --> ignore
      endcase
    endfor
  endif

  if (segSelect.FOM gt 0.) and (ADD eq 1) then begin;  The segment will be removed if segSelect.FOM==0
    newDISCUSSION = [newDISCUSSION, segSelect.DISCUSSION]
    newSOURCEID   = [newSOURCEID, !SPPEVA.USER.ID]
    newSTART      = [newSTART, segSelect.TS]
    newSTOP       = [newSTOP,  segSelect.TE]
    newFOM        = [newFOM,   segSelect.FOM]
  endif

  ;------------------------------------
  ; REPLACE OLD FOMSTR WITH NEW FOMSTR
  ;------------------------------------
  nmax = n_elements(newFOM)
  if nmax ge 2 then begin
    SOURCEID   = newSOURCEID[1:nmax-1]
    START      = newSTART[1:nmax-1]
    STOP       = newSTOP[1:nmax-1]
    DISCUSSION = newDISCUSSION[1:nmax-1]
    FOM        = newFOM[1:nmax-1]
    idx = sort(START)
    str_element,/add,s,'Nsegs',nmax - 1
    ;str_element,/add,s,'tr',s.TR
    str_element,/add,s,'SOURCEID',SOURCEID[idx]
    str_element,/add,s,'START', START[idx]
    str_element,/add,s,'STOP', STOP[idx]
    str_element,/add,s,'DISCUSSION',DISCUSSION[idx]
    str_element,/add,s,'FOM',FOM[idx]
  endif else begin
    s = {Nsegs:0L}
  endelse
  
  ;------------------
  ; FOMSTR --> TPLOT
  ;------------------
  sppeva_sitl_strct2tplot, s, var

END
