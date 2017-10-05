FUNCTION eva_data_load_mms_jtot, sc=sc,curlB=curlB,diffB=diffB,combB=combB, LOADED_4FGM=LOADED_4FGM, no_gui=no_gui
  
  if LOADED_4FGM eq 0 then begin
    eva_data_load_mms_fgm, sc='mms1'
    eva_data_load_mms_fgm, sc='mms2'
    eva_data_load_mms_fgm, sc='mms3'
    eva_data_load_mms_fgm, sc='mms4'
    LOADED_4FGM = 1L
  endif
  
  if keyword_set(combB) then begin
    curlB = 1L
    diffB = 1L
  endif
  
  if keyword_set(curlB) then begin
    mms_sitl_curl_b, flag, /no_load
    if flag eq 1 then begin
      msg = 'Skipping curl-B (Missing Bfield data from one or more spacecraft)'
      print, 'EVA: '+msg
;      if keyword_set(no_gui) then begin
;        print, msg
;      endif else begin
;        result = dialog_message(msg,/center)
;      endelse
      LOADED_4FGM = 0L
    endif
    tn = tnames('mms_sitl_jtot_curl_b',cnt)
    if cnt eq 1 then begin
      options, tn, ytitle='curlB',ysubtitle='uA/m!U2!D'
    endif
  endif
  
  if keyword_set(diffB) then begin
    mms_sitl_diffb, flag, /no_load
    if flag eq 1 then begin
      msg = 'Skipping diffb (Need at least two spacecraft).'
      print, 'EVA: '+msg
;      if keyword_set(no_gui) then begin
;        print, msg
;      endif else begin
;        result = dialog_message(msg,/center)
;      endelse
      LOADED_4FGM = 0L
    endif else begin
      tn = tnames('mms_sitl_diffB',cnt)
      if cnt eq 1 then begin
        options,tn,labflag=-1,labels='diff-B!U2'
        tclip, tn, 0, 10.,/overwrite
      endif
    endelse
  endif

  if keyword_set(combB) then begin
    tn1 = tnames('mms_sitl_jtot_curl_b',c1)
    tn2 = tnames('mms_sitl_diffB',c2)
    if (c1 eq 1) and (c2 eq 1) then begin
      store_data,'mms_sitl_jtot_combB',data='mms_sitl_'+['jtot_curl_b','diffB']
      options,'mms_sitl_jtot_combB',colors=[6,0,2],labflag=-1,$
        labels=['curlB_err','curlB','diffB'],$
        ytitle='Jtot',ysubtitle='uA/m!U2!D'
    endif else begin
      if (c1 eq 1) then begin
        store_data,'mms_sitl_jtot_combB',data=['mms_sitl_jtot_curl_b']
        options,'mms_sitl_jtot_combB',colors=[6,0],labflag=-1,$
          labels=['curlB_err','curlB'],$
          ytitle='Jtot',ysubtitle='uA/m!U2!D'
      endif
      if (c2 eq 1) then begin
        store_data,'mms_sitl_jtot_combB',data=['mms_sitl_diffB']
        options,'mms_sitl_jtot_combB',colors=[2],labflag=-1,$
          labels=['diffB'],$
          ytitle='Jtot',ysubtitle='uA/m!U2!D'
      endif
    endelse

  endif
  return, LOADED_4FGM
END
