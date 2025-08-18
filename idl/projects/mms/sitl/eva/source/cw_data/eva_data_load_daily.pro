
FUNCTION eva_data_load_daily_check, save_var, date
  @tplot_com
  names=tnames('*',nmax,ind=ind)
  tobeDL = 0 ; NOT to be downloaded
  for s=0,n_elements(save_var)-1 do begin; for each required variable
    index = where(strmatch(names,save_var[s]),count)
    case count of
      0:  begin; if not found then download
        tobeDL = 1
      end
      1:  begin; if found, check time range
        i  = ind[index[0]]
        dq = data_quants[i]
        tr = time_string(dq.trange,precision=7)
        da1= strmid(tr[0],0,10); get date
        da2= strmid(tr[1],0,10); get date
        if not (strcmp(date,da1) and strcmp(date,da2)) then tobeDL = 1; to be downloaded
      end
      else:begin
      print, 'EVA: !!!!! ERROR: something is wrong with count (eva_data_load_daily_check) !!!!!'
      stop
    end
  endcase
endfor; for each required variable
return, tobeDL
END

FUNCTION eva_data_load_daily_prbarr, arr, ilbl
  offset = 2 ; filenames have two-letter offset to indicate mission name. e.g. thb_, thad_, mma_,mmb_
  lbl = strmid(arr,0,offset)
  nmax = strlen(arr)-offset
  prbarr = strarr(nmax)
  for n=0,nmax-1 do begin
    if ilbl then prbarr[n] = lbl + strmid(arr,n+offset,1) $
    else prbarr[n] = strmid(arr,n+offset,1)
  endfor
  return, prbarr
END

FUNCTION eva_data_load_daily, filename, dir, nolog=nolog
  @tplot_com

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    if ~keyword_set(nolog) then begin
      eva_error_message, error_status, msg='filename= '+filename
    endif else begin
      help, /last_message, output=error_message; get error message
      for jjjj=0,n_elements(error_message)-1 do begin
        print,error_message[jjjj]
      endfor
    endelse
    return, 'No'
  endif

  ; INITIALIZE

  arr      = strsplit(filename,'_',/extract)
  date     = arr[0]; date
  sc       = arr[1]; spacecraft
  datatype = arr[2]; datatype such as fgl, peir, etc.
  if n_elements(arr) ge 4 then begin
    prod_arr = strsplit(arr[3],'.',/extract)
    prod     = prod_arr[0]; data product, e.g. velocity, edc
  endif else begin
    prod   = ''
  endelse
  type     = datatype
  check    = strpos(datatype,'.')
  if check ge 0 then type = strmid(datatype,0,3)
  prbs     = eva_data_load_daily_prbarr(arr[1],0)
  probes   = eva_data_load_daily_prbarr(arr[1],1)
  pmax     = n_elements(prbs)
  tname    = strmid(filename,11,strlen(filename)-17)
  timespan, str2time(date),1
  save_var = strarr(1)
  instr    = strmid(type,0,2)
  msn      = strmid(sc,0,2)

  if ~keyword_set(nolog) then begin
  print, 'EVA: ----- Generating file : '+ filename+ ' -----'
  print, 'EVA: msn  = '+msn
  print, 'EVA: date = '+date
  print, 'EVA: type = '+type
  print, 'EVA: prod = '+prod
  print, 'EVA: prbs = '+prbs
  print, 'EVA: probes = '+probes
  print, 'EVA: tname = '+tname
  endif


  ; COORDINATE
  coord = 'gsm'; default (to be obtained from GUI) (code later)
  if strpos(tname,'gsm') ge 0 then coord = 'gsm'
  if strpos(tname,'gse') ge 0 then coord = 'gse'
  if strpos(tname,'dsl') ge 0 then coord = 'dsl'



  ; MAIN
  if eva_data_load_daily_check(tname,date) then begin; check if the tplot variable already exists

    ; LOAD CDF FILES
    matched = 0

    if strmatch(type,'idx') then begin
      thm_load_pseudoAE,datatype='ae'
      if tnames('thg_idx_ae') eq '' then begin
        store_data,'thg_idx_ae',data={x:time_double(date)+dindgen(2), y:replicate(!values.d_nan,2)}
      endif
      options,'thg_idx_ae',ytitle='THEMIS!CAE Index'
      matched = 1
    endif

    if strmatch(type,'fb') then begin
      thm_load_fbk,probe=prbs,level=2;,datatype=['fb_'+type]
      matched = 1
    endif

    if strmatch(type,'fg?') then begin
      thm_load_fgm,probe=prbs,level=2,coord=coord,datatype=type
      matched = 1
    endif

    ;    if strmatch(type,'Your_data_type') then begin
    ;      load_your_data
    ;      matched = 1
    ;    endif

    if strmatch(type,'pe?m') then begin
      thm_load_mom,probe=prbs,level=2,coord=coord; there is only one option for datatype (default)
      matched = 1
    endif

    if (strmatch(type,'pe?r') or strmatch(type,'pe?f') or strmatch(type,'pe?b')) then begin
      datatype = [type+'_density',type+'_velocity_*',type+'_avgtemp',type+'_magt3']
      thm_load_esa,probe=prbs,level=2,coord=coord,datatype=datatype
      matched = 1
    endif


    
    if strmatch(type,'pt*') then begin
      idx = where(strmatch(tnames(),tname),ct)
      if ct ne 1 then begin
        trange = time_string(timerange(/current))
        spc = strmid(type,2,1)
        esa_datatype = 'pe'+spc+strmid(type,3,1)
        sst_datatype = 'ps'+spc+strmid(type,4,1)
        ;----------------
        ; Load
        ;----------------
        ;time intervals longer than 1-2 hours may be memory and times intensive
        combined = thm_part_combine(probe=prbs[0], trange=trange, $
          esa_datatype=esa_datatype, sst_datatype=sst_datatype, $
          orig_esa=esa, orig_sst=sst)
        ;----------------
        ; Process
        ;----------------
        if (strpos(tname,'energy') ge 0) then begin
          if (strpos(tname,'df') ge 0) then begin
            thm_part_products, dist_array=combined, outputs='energy',units='df'
          endif else begin
            thm_part_products, dist_array=combined, outputs='energy'
          endelse
        endif else begin
          thm_part_products, dist_array=combined, outputs='moments'
          if strpos(tname,'velocity') ge 0 then begin
            thm_load_state,probe=prbs, /get_support_data
            code = probes+'_'+type+'_'+prod
            thm_cotrans,code,out_suf='_'+coord,out_c=coord
          endif
        endelse
      endif; if ct ne 1
      matched=1
    endif

    if strmatch(type,'ps??') then begin
      allzeros=[0,8,24,32,40,47,48,55,56]
      bins2mask=make_array(64,/int,value=1)
      bins2mask(allzeros)=0
      units = 'eflux'; 'df' or 'eflux'
      thm_part_getspec, probe=prbs,data_type=type,units=units, suffix='_et_omni',$
        /energy;, enoise_bins=bins2mask, enoise_remove_method='fill';,/sst_cal
      matched = 1
    endif
    
    if strmatch(type,'ef*') then begin
      idx = where(strmatch(tnames(),tname),ct)
      if ct ne 1 then begin
        thm_load_state,probe=prbs,/get_sup
        thm_load_efi,probe=prbs,coord='dsl',type='calibrated'
      endif
      matched=1
    endif
    
    if strmatch(type,'ffp') then begin
      idx = where(strmatch(tnames(),tname),ct)
      if ct ne 1 then begin
        thm_load_fft,probe=prbs
      endif
      matched=1  
    endif
    
    if strmatch(type,'np*') then begin
      probe=probes[0]
      thm_load_esa, probe=prbs, datat=' peer_avgtemp pe?r_density peer_sc_pot ', level=2
      get_data,probe+'_peer_density',data=d & dens_e= d.y & dens_e_time= d.x
      get_data,probe+'_peir_density',data=d & dens_i= d.y & dens_i_time= d.x
      get_data,probe+'_peer_sc_pot',data=d & sc_pot = d.y & sc_pot_time = d.x
      get_data,probe+'_peer_avgtemp',data=d & Te = d.y & Te_time = d.x
      Npot = thm_scpot2dens(sc_pot, sc_pot_time, Te, Te_time, dens_e, dens_e_time, dens_i, dens_i_time, prbs)
      store_data, probe+'_Npot', data= { x: sc_pot_time, y: Npot }
      store_data, probe+'_Npot_compare', data = [probe+'_Npot',probe+'_peer_density',probe+'_peir_density' ]
      options, probe+'_peer_density', 'color', 2  ;trace .............. blue
      options, probe+'_peer_density', 'colors', 2  ;label
      options, probe+'_peer_density', 'labels', 'Ne'
      options, probe+'_peir_density', 'color', 4 ;........ green
      options, probe+'_peir_density', 'colors', 4
      options, probe+'_peir_density', 'labels', 'Ni'
      options, probe+'_Npot', 'labels', probe+'_Npot;......black
      options, probe+'_Npot', 'colors', 0
      options, probe+'_Npot', 'color', 0
      options, probe+'_Npot', 'ylog', 1
      matched=1  
    endif
    
    if strmatch(type,'state') then begin
      thm_load_state, probe=prbs
      probe = probes[0]
      if(coord eq 'gsm') then begin
        cotrans,probe+'_state_pos',probe+'_state_pos_gse',/gei2gse
        cotrans,probe+'_state_vel',probe+'_state_vel_gse',/gei2gse
        cotrans,probe+'_state_pos_gse',probe+'_state_pos_gsm',/gse2gsm
        cotrans,probe+'_state_vel_gse',probe+'_state_vel_gsm',/gse2gsm
      endif
      matched=1
    endif
    
    if ~matched then begin
      stop
      msgtxt = filename + ' could not be loaded.'
      result = dialog_message(msgtxt)
      if ~keyword_set(nolog) then print, 'EVA: '+msgtxt
      return, 'No'
    endif

    save_var = [save_var, tname]

  endif else begin; if tname existed
    save_var = [save_var, tname]
  endelse

  ; SAVE
  if n_elements(save_var) gt 1 then begin
    rst = 1
    ;    if strmatch(filename,'*tdn*') then rst = 0
    ;    if strmatch(filename,'*cdq*') then rst = 0
    ;    if strmatch(filename,'*mdq*') then rst = 0
    ;    if strmatch(filename,'*fom*') then rst = 0



    ; tplot_save
    if rst then begin
      tpv = save_var[1:*]

      ; additional tplot_variable
      index = where(strmatch(tpv,'mms_stlm_output_fom'),c)
      if c eq 1 then begin
        tpv = [tpv,'mms_stlm_input_fom']
      endif

      yyyy  = strmid(date,0,4)
      mmdd  = strmid(date,5,5)
      svdir = dir+yyyy+'/'+mmdd+'/'
      ;fullname = svdir + strmid(filename,0,strlen(filename)-6)
      fullname = svdir + filename
      file_mkdir,svdir

      print, 'EVA: dir='+dir
      tplot_save,file=fullname,tpv
    endif
    answer = 'Yes'
  endif else begin
    answer = 'No'
  endelse

  return, answer
END
