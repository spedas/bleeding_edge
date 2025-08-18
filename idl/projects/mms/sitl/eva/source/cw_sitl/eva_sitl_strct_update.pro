;+
; NAME:
;   EVA_SITL_STRCT_UPDATE
;   
; COMMENT:
;   If a SITL modifies a segment, the information of the segement will be stored in
;   "segSelect" and is passed to this program. This program will then make changes
;   (add, split/combine,etc) to the FOM/BAK structure file. 
; 
; $LastChangedBy: moka $
; $LastChangedDate: 2024-07-11 12:49:49 -0700 (Thu, 11 Jul 2024) $
; $LastChangedRevision: 32735 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/cw_sitl/eva_sitl_strct_update.pro $
;
PRO eva_sitl_strct_update, segSelect, user_flag=user_flag, BAK=BAK, OVERRIDE=OVERRIDE
  compile_opt idl2
  
  if n_elements(user_flag) eq 0 then user_flag = 0

  defSourceID = eva_sourceid()

  get_data,'mms_stlm_fomstr',data=D,lim=lim,dl=dl
  s = lim.UNIX_FOMSTR_MOD
  tfom = eva_sitl_tfom(s)

  ;validation
  if not keyword_set(BAK) then begin
    r = segment_overlap([segSelect.TS,segSelect.TE],tfom)
    case r of
      -1: segSelect.TS = tfom[0]
       1: segSelect.TE = tfom[1]
       2: message,'Something is wrong'
  ;     3: message,'Something is wrong'
  ;     Commented out on 2015 Jun 16. We needed to select the entire target time for testing.
  ;     So, it is okay if the selected segment was exactly the same as 'tfom'.
      else:;-2 or 0 --> OK
    endcase
  endif
  
  ;main (Determine if segSelect is for FOMStr or BAKStr)
  r = segment_overlap([segSelect.TS,segSelect.TE],tfom)
  if (keyword_set(BAK) or segSelect.BAK) then r=-2
  
  if (r eq 0) or (r eq 3) then begin
    ;----------------------
    ; FOMStr
    ;----------------------
    
    result = min(abs(s.TIMESTAMPS-segSelect.TS),segSTART)
    result = min(abs(s.TIMESTAMPS-segSelect.TE),segSTOP); 1084
    segSTOP -= 1 ; 1083
    segSelectTime = [s.TIMESTAMPS[segSTART], s.TIMESTAMPS[segSTOP+1]]
    
    ; To properly select the last trigger-cycle, we need to consider
    ; the end time of the last trigger-cycle. Note that TIMESTAMPS
    ; refer to the start time of each trigger-cycle. Even if segSelect.TE
    ; is larger than TIMESTAMPS[NUMCYCLES-1]+10 (or tfom[1]), the above lines
    ; will select TIMESTAMPS[NUMCYCLES-1] as the end time of the
    ; selected (desired) segment.
    if (segSelect.TE ge tfom[1]) then begin
      segSTOP += 1; 1084
      segSelectTime[1] = tfom[1]
    endif
    
    ; a plain clean selection with no segment
    newSEGLENGTHS = 0L
    newSOURCEID   = ' '
    newSTART      = 0L
    newSTOP       = 0L
    newFOM        = 0.
    newDISCUSSION    = ' '
    newISPENDING  = 1L
    newOBSSET     = 15B
    
    ; scan all segments
    for N=0,s.Nsegs-1 do begin
      ss = s.TIMESTAMPS[s.START[N]]; segment start time
      ;se = s.TIMESTAMPS[s.STOP[N]+1]; segment stop time
      
      dtlast = s.TIMESTAMPS[s.NUMCYCLES-1L]-s.TIMESTAMPS[s.NUMCYCLES-2L]
      se = (s.STOP[N] ge s.NUMCYCLES-1L) ? s.TIMESTAMPS[s.NUMCYCLES-1]+dtlast : s.TIMESTAMPS[s.STOP[N]+1]
      
      ; Each segment is compared to the User's new/modified segment
      rr = segment_overlap([ss,se],segSelectTime)
      case abs(rr) of; 
        1: begin; partial overlap --> split
          if rr eq -1 then begin
            if segSTART eq 0 then message,'Something is wrong';segSTART += 1L
            newSTART = [newSTART, s.START[N]]
            newSTOP  = [newSTOP, segSTART-1]
            newSEGLENGTHS = [newSEGLENGTHS, segSTART - s.START[N]] 
          endif else begin
            if segSTOP gt s.NUMCYCLES-1 then message,'Something is wrong'
            newSTART = [newSTART, segSTOP+1]
            newSTOP  = [newSTOP, s.STOP[N]]
            newSEGLENGTHS = [newSEGLENGTHS, s.STOP[N] - segSTOP]
          endelse
          newDISCUSSION    = [newDISCUSSION, s.DISCUSSION[N]]
          newOBSSET     = [newOBSSET, s.OBSSET[N]]
          newSOURCEID   = [newSOURCEID, defSourceID]
          newFOM        = [newFOM,s.FOM[N]]
          end
        2: begin; no overlap --> preserve this segment
          newSEGLENGTHS = [newSEGLENGTHS, s.SEGLENGTHS[N]]
          newSOURCEID   = [newSOURCEID, s.SOURCEID[N]]
          newDISCUSSION = [newDISCUSSION, s.DISCUSSION[N]]
          newOBSSET     = [newOBSSET, s.OBSSET[N]] 
          newSTART      = [newSTART, s.START[N]]
          newSTOP       = [newSTOP, s.STOP[N]]
          newFOM        = [newFOM,s.FOM[N]]
          end
        else:; rr=0 or 3 --> contained in segSelect --> remove
      endcase
    endfor
    
    ;add selected segment
    if segSelect.FOM gt 0. then begin; The segment will be removed if segSelect.FOM==0
      newSEGLENGTHS = [newSEGLENGTHS, segSTOP-segSTART+1]
      newFOM        = [newFOM,segSelect.FOM]
      ;newISPENDING  = [newISPENDING, 1L]
      newSOURCEID   = [newSOURCEID, defSourceID]
      newSTART      = [newSTART, segSTART]
      newSTOP       = [newSTOP, segSTOP]
      newDISCUSSION = [newDISCUSSION,segSelect.DISCUSSION]
      newOBSSET     = [newOBSSET, segSelect.OBSSET] 
    endif
    
    ;update FOM structure
    Nmax = n_elements(newFOM)
    newNsegs = Nmax - 1
    
    if newNsegs ge 1 then begin
      str_element,/add,s,'SEGLENGTHS',long(newSEGLENGTHS[1:Nmax-1])
      str_element,/add,s,'SOURCEID', newSOURCEID[1:Nmax-1]
      str_element,/add,s,'START',long(newSTART[1:Nmax-1])
      str_element,/add,s,'STOP',long(newSTOP[1:Nmax-1])
      str_element,/add,s,'FOM',float(newFOM[1:Nmax-1])
      str_element,/add,s,'NSEGS',long(newNsegs)
      str_element,/add,s,'NBUFFS',long(total(newSEGLENGTHS[1:Nmax-1]))
      str_element,/add,s,'DISCUSSION',newDISCUSSION[1:Nmax-1]
      str_element,/add,s,'OBSSET',byte(newOBSSET[1:Nmax-1])
      
      s = eva_sitl_strct_sort(s)
      
      
      ;str_element,/add,s,'ISPENDING',newISPENDING[1:Nmax-1]
      ;update 'mms_sitl_fomstr'
      D = eva_sitl_strct_read(s,tfom[0])
      store_data,'mms_stlm_fomstr',data=D,lim=lim,dl=dl; update data points
      options,'mms_stlm_fomstr','unix_FOMStr_mod',s ; update structure
      
      
      ;update yrange
      eva_sitl_strct_yrange,'mms_stlm_output_fom'
      eva_sitl_strct_yrange,'mms_stlm_fomstr'

      eva_sitl_copy_fomstr
      
    endif else begin; No segment
      if ~keyword_set(override) then begin
        r = dialog_message("You can't delete all segments.",/center)
      endif
    endelse
  endif else begin;if (r eq 0) or (r eq 3) then begin
    ;----------------------
    ; BAKStr
    ;----------------------
    ; Already validated in 'eva_sitl' so that [segSelect.TS,segSelect.TE] 
    ; (1) does not overlap with any other segment (ADD)
    ; (2) matches exactly with one of the existing segments. (EDIT)
    ; In case of DELETE, simply delete all segments within [segSelect.TS,segSelect.TE]
    if (r eq -2) then begin
      get_data,'mms_stlm_bakstr',data=D,lim=lim,dl=dl
      s = lim.UNIX_BAKSTR_MOD
      Nsegs = n_elements(s.FOM)
      matched=0
      for N=0,Nsegs-1 do begin; scan all segment
        rr = segment_overlap([s.START[N],s.STOP[N]+10.d0],[segSelect.TS,segSelect.TE])
        if (rr eq 3)  then begin
          if segSelect.FOM gt 0 then begin;.................. EDIT
            s.FOM[N]    = segSelect.FOM
            s.STATUS[N] = 'MODIFIED'
            s.CHANGESTATUS[N] = 1L; REQUIRED BY RICK (signifies the segment was modified)
            s.SOURCEID[N] = defSourceID
            s.DISCUSSION[n] = segSelect.DISCUSSION
            s.OBSSET[n]    = segSelect.OBSSET
          endif else begin;............................ DELETE
            s.STATUS[N] = 'DELETED'
            s.CHANGESTATUS[N] = 2L; REQUIRED BY RICK (signifies the segment was deleted) 
            s.SOURCEID[N] = defSourceID
          endelse
          matched=1
        endif
      endfor
      if ~matched then begin;..................... ADD
        str_element,/add,s,'START',[s.START, long(segSelect.TS)]
        str_element,/add,s,'STOP', [s.STOP,  long(segSelect.TE-10.d0)]
        str_element,/add,s,'FOM',  [s.FOM,   segSelect.FOM]
        str_element,/add,s,'SEGLENGTHS',[s.SEGLENGTHS, floor((segSelect.TE-segSelect.TS)/10.d)]
        str_element,/add,s,'CHANGESTATUS',[s.CHANGESTATUS, 0L]; REQUIRED BY RICK (signifies the segment was added)
        str_element,/add,s,'DATASEGMENTID',[s.DATASEGMENTID, -1L]; REQUIRED BY SDC (all segment must have an ID) 
        str_element,/add,s,'PARAMETERSETID',[s.PARAMETERSETID, ''];the revision ID of a BDM configuration file for FOM calculation
        str_element,/add,s,'ISPENDING',[s.ISPENDING,0L]
        str_element,/add,s,'INPLAYLIST',[s.INPLAYLIST,0L]
        str_element,/add,s,'STATUS', [s.STATUS,'NEW']
        ; STATUS should be one or more of the followings:
        ; NEW, DERELILCT, ABORTED, HELD, DEMOTED, INCOMPLETE, REALLOC, MODIFIED, COMPLETE,
        ; DEFERRED, DELETED, FINISHED
        str_element,/add,s,'NUMEVALCYCLES',[s.NUMEVALCYCLES, 0L]; how many times a segment has been evaluated by BDM
        str_element,/add,s,'SOURCEID',[s.SOURCEID,defSourceID]; the SITL responsible for defining the segment
        str_element,/add,s,'CREATETIME',[s.CREATETIME,'']; the UTC time the segment was defined and entered into BDM
        str_element,/add,s,'FINISHTIME',[s.FINISHTIME,'']; the UTC time when the segment was no longer pending any more processing.
        str_element,/add,s,'DISCUSSION',[s.DISCUSSION,segSelect.DISCUSSION]
        str_element,/add,s,'OBSSET',    [s.OBSSET, segSelect.OBSSET]
      endif

      ; cleanup (added on 2016-09-12)
      for N=0, Nsegs-1 do begin; scan all segment
        idx = where(s.CHANGESTATUS eq 2L and s.DATASEGMENTID eq -1L, ct, comp=comp, ncomp=ncomp)
        if ct gt 0 then begin
          str_element,/add,s,'CHANGESTATUS' ,s.CHANGESTATUS[comp]
          str_element,/add,s,'CREATETIME'   ,s.CREATETIME[comp]
          str_element,/add,s,'DATASEGMENTID',s.DATASEGMENTID[comp]
          str_element,/add,s,'DISCUSSION'   ,s.DISCUSSION[comp]
          str_element,/add,s,'FINISHTIME'   ,s.FINISHTIME[comp]
          str_element,/add,s,'FOM'          ,s.FOM[comp]
          str_element,/add,s,'INPLAYLIST'   ,s.INPLAYLIST[comp]
          str_element,/add,s,'ISPENDING'    ,s.ISPENDING[comp]
          str_element,/add,s,'NBUFFS'       ,long(total(s.SEGLENGTHS[comp]))
          str_element,/add,s,'NUMEVALCYCLES',s.NUMEVALCYCLES[comp]
          str_element,/add,s,'PARAMETERSETID',s.PARAMETERSETID[comp]
          str_element,/add,s,'SEGLENGTHS'   ,s.SEGLENGTHS[comp]
          str_element,/add,s,'SOURCEID'     ,s.SOURCEID[comp]
          str_element,/add,s,'START'        ,s.START[comp]
          str_element,/add,s,'STATUS'       ,s.STATUS[comp]
          str_element,/add,s,'STOP'         ,s.STOP[comp]
          str_element,/add,s,'OBSSET'       ,s.OBSSET[comp]
        endif
      endfor
      
      ;update 'mms_sitl_bakstr'
      D = eva_sitl_strct_read(s,min(s.START,/nan),/quiet)
      store_data,'mms_stlm_bakstr',data=D,lim=lim,dl=dl; update data points
      options,'mms_stlm_bakstr','unix_BAKStr_mod',s ; update structure
      
      ;update yrange
      eva_sitl_strct_yrange,'mms_stlm_bakstr';'mms_stlm_output_fom'
      eva_sitl_strct_yrange,'mms_stlm_fomstr'
      
    endif else begin;if (r eq -2) then begin
      print, 'r=',r
      message,'Something is wrong'
    endelse
  endelse;if (r eq 0) or (r eq 3) then begin
END
