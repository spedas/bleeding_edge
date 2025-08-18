;+
;NAME:
;  spd_ui_pwrspc
;
;PURPOSE:
;  Creates power spectra from GUI variables that are active in the Process Data
;  window and loads the spectra into the loadedData object.  Directly calls
;  PWRSPC and DPWRSPC to create the spectra.  Intended to be called from
;  SPD_UI_DPROC.
;
;CALLING SEQUENCE:
;  spd_ui_pwrspc, options,invars, loadedData, historyWin, statusBar,guiID
;
;INPUT:
;  options: Structure that is output from SPD_UI_PWRSPC_OPTIONS containing
;           keyword options for PWRSPC and DPWRSPC.
;  loadedData: The loadedData object.
;  historyWin: The history window object.
;  statusBar: The status bar object for the Data Processing window.
;  guiid:  The widget id for the GUI so that it can display prompts with the correct layering.
;  
;KEYWORDS:
;  
;
;OUTPUT:
;  none
;-


function spd_ui_pwrspc_check_time, time, tbegin, tend
  ; This code duplicates what's being done in dpwrspc, but we need it here so
  ; we can produce GUI error messages.
  
  compile_opt idl2, hidden

  if keyword_set(tend) then begin
    t2 = tend
  endif else begin
    t2 = time[n_elements(time)-1]
  endelse

  if keyword_set(tbegin) then begin
    t1 = tbegin
  endif else begin
    t1 = time[0]
  endelse

  igood = where((time ge t1) and (time le t2), jgood)
  if (jgood gt 0) then return, 1 else return, 0

end


pro spd_ui_pwrspc, options,invars, loadedData, historyWin, statusBar,guiID, $
                       fail=totalfail, overwrite_selections = overwrite_selections, $
                       replay = replay

  compile_opt idl2
  
  ; error catch
  err = 0
  catch, err
  If(err Ne 0) Then Begin
      catch, /cancel
      Help, /Last_Message, Output=err_msg
      if obj_valid(historywin) then historywin -> update, err_msg
      ok = error_message(traceback = 1, /noname, title = 'Error in SPD_UI_PWRSPC: ')
      totalfail = 1
      return
  Endif
  
  totalfail=1
  fail=0
  
  ;Initialize output
  add_names = ''
  
  overwrite_selection = ''
  overwrite_count = 0
  if undefined(replay) then overwrite_selections = ''

  active_v = invars
  
  nav = n_elements(active_v)
  
  for i=0, nav-1 do begin
    varname = active_v[i]
    loadedData->getvardata, name=varname, time=t, data=d, limits=l, dlimits=dl
    
    sd = size(*d, /n_dim)
    ncomp = n_elements((*d)[0, *]) ; the number of components of variable
    if (sd gt 2) then begin
      mess = varname + ': data has too many dimensions and will not be processed.'
      statusBar->update, mess
      historyWin->update, 'SPD_UI_PWRSPC: ' + mess
      yes_data = 0b
      fail = 1
    endif else yes_data = 1b
    
    if yes_data then begin
         
      ; check that there's data w/in requested time range
      tsuccess = spd_ui_pwrspc_check_time(*t, options.tbegin[0], options.tend[0])
      if options.dynamic[0] AND ~tsuccess then begin
        mess = varname + ': No data in time range. Moving on to next active variable.'
        statusBar->update, mess
        historyWin->update, 'SPD_UI_PWRSPC: ' + mess
        fail = 1
        continue
      endif
    
      ; setup suffixes for power spec var names
      case ncomp of
        1: dsuffix = ''
        3: if keyword_set(polar) then dsuffix = ['_mag','_th','_phi'] $
            else dsuffix = ['_x','_y','_z']
        ;6: dsuffix = '_'+strsplit('xx yy zz xy xz yz',/extract)
        else: dsuffix = '_' + strtrim(lindgen(ncomp),2)
      endcase
      
      
      
      for j=0, ncomp-1 do begin
        if ptr_valid(l) then limit = *l else limit = 0
        if ptr_valid(dl) then dlimit = *dl else dlimit = 0
     
        tpts = n_elements(*t)
        nanidx = where(finite((*d)[*,j]),c)
         
        if c gt 0 && c lt tpts && ~options.scrubnans then begin
          message = 'NaNs found in ' + varname + ' component ' + strtrim(j, 2) + '. May cause gaps in Power Spectrum.  Degap or Scrub to eliminate errors.'
          statusBar -> update, message
          historywin -> update, message
          warnNaNs = 1
        endif
    
        if c eq 0 then begin    ;jmm, 27-Jan=2011
          message = 'All NaNs found in ' + varname + ' component ' + strtrim(j,2) + '. No Power Spectrum performed for this component'
          statusBar -> update, message
          historywin -> update, message
          warnNaNs = 1
          fail = 1
          continue
        endif
    
        if options.dynamic[0] then begin
          
          ; check to make sure there are enough points for a calculation
         
          nspectra = long((tpts-options.nboxpoints[0]/2l)/options.nshiftpoints[0])
          if(nspectra le 0) then begin
            mess = 'Window Size too small for ' + varname + dsuffix[j] + ', and it will not be processed.'
            statusBar->update, mess
            historyWin->update, 'SPD_UI_PWRSPC: ' + mess
            fail = 1
            continue
          endif
          
          if c lt tpts && options.scrubnans then begin
            message = 'Scrubbing NaNs from ' + varname + ' component ' + strtrim(j,2) + '.'
            statusBar->update,message
            historywin->update,message
            dpwrspc, (*t)[nanidx], (*d)[nanidx,j], tps, fdps, dps, nboxpoints=options.nboxpoints[0], $
                  nshiftpoints=options.nshiftpoints[0], bin=options.bins[0], $
                  tbegin=options.tbegin[0], tend=options.tend[0], noline=options.noline[0], $
                  nohanning=options.nohanning[0], notperhz=options.notperhz[0],fail=specfail
          endif else begin
            dpwrspc, *t, (*d)[*,j], tps, fdps, dps, nboxpoints=options.nboxpoints[0], $
              nshiftpoints=options.nshiftpoints[0], bin=options.bins[0], $
              tbegin=options.tbegin[0], tend=options.tend[0], noline=options.noline[0], $
              nohanning=options.nohanning[0], notperhz=options.notperhz[0],fail=specfail
          endelse
                  
          if specfail then begin
            fail = 1
            continue
          endif        
                  
          specdata = {x:temporary(tps), y:temporary(dps), v:temporary(fdps)}
  
          isspect=1
          if in_set('xlog', strlowcase(tag_names(dlimit))) then dlimit.xlog = 0 $
            else str_element, dlimit, 'xlog', 0, /add
  
        endif else begin

          if c lt tpts && options.scrubnans then begin
            message = 'Scrubbing NaNs from ' + varname + ' component ' + strtrim(j,2) + '.'
            statusBar->update,message
            historywin->update,message
            pwrspc, (*t)[nanidx], (*d)[nanidx,j], freq, power, noline=options.noline[0], $
                 nohanning=options.nohanning[0], bin=options.bins[0], $
                 notperhz=options.notperhz[0], err_msg=pwrspc_err_msg
          endif else begin
            pwrspc, *t, (*d)[*,j], freq, power, noline=options.noline[0], $
                 nohanning=options.nohanning[0], bin=options.bins[0], $
                 notperhz=options.notperhz[0], err_msg=pwrspc_err_msg
          endelse

          if ~array_equal(pwrspc_err_msg,'', /no_typeconv) then begin
            historyWin->update, ['SPD_UI_PWRSPC: Error with '+varname+': ', $
                                 '     '+pwrspc_err_msg]
            statusBar->update, ['Error with '+varname+': '+pwrspc_err_msg]
            fail=1
          endif

          avg_time = (dblarr(n_elements(freq)) + 1) * mean(*t, /double)
          specdata = {x:avg_time, y:temporary(power)}
          freqdata = {x:avg_time, y:temporary(freq)}
          
          isspect=0
          str_element, dlimit, 'xlog', 1, /add
            
        endelse
        
        ; set general dlimits
        str_element, dlimit, 'ylog', 1, /add
  
        str_element, dlimit, 'zlog', 1, /add
        
        str_element,dlimit,'labels',value=labels,success=s
        if s && n_elements(labels) eq ncomp then begin
          str_element,dlimit,'labels',[dlimit.labels[j]],/add
        endif
        
        str_element,dlimit,'colors',value=colors,success=s
        if s && n_elements(colors) eq ncomp then begin
          str_element,dlimit,'colors',[dlimit.colors[j]],/add
        endif
        
        ; add data to loadedData object
        if options.suffix[0] eq '' then options.suffix[0] = '_pwr'
        specname = varname + dsuffix[j] + options.suffix[0]
        freqname = specname + '_freq'
        
        ; check if we're overwriting 'specname'
        spd_ui_check_overwrite_data,specname,loadedData,guiId,statusBar,historyWin,overwrite_selection,overwrite_count,$
                                 replay=replay,overwrite_selections=overwrite_selections
        if strmid(overwrite_selection, 0, 2) eq 'no' then continue
        
        if options.dynamic[0] then begin
                
          success = loadedData->addData(specname, specdata, limit=limit, $
                    dlimit=dlimit, isspect=isspect)
          if success then add_names=[add_names, specname]
        endif else begin
          
          success = loadedData->addData(specname, specdata, limit=limit, $
                    dlimit=dlimit, isspect=isspect, indepName=freqname)
                    
          if success then add_names=[add_names, specname]
          
          ; check if we're overwriting 'freqname'
          spd_ui_check_overwrite_data,freqname,loadedData,guiId,statusBar,historyWin,overwrite_selection,overwrite_count,$
                                 replay=replay,overwrite_selections=overwrite_selections
          if strmid(overwrite_selection, 0, 2) eq 'no' then continue
          
          ; add indep data of power spectra as a separate variable
          success2 = loadedData->addData(freqname, freqdata, limit=limit, dlimit=dlimit, isspect=isspect)
          if success2 then add_names=[add_names, freqname]
          
        endelse
           
      endfor
  
      ;Reset active data to new variables, if there are any
      if ~array_equal(add_names, '') then begin
        totalfail = 0
        loadedData->clearAllActive
        for j=1, n_elements(add_names)-1 do loadedData->setActive, add_names[j]
      endif
  
    endif
    
  endfor
  
  if fail then begin
    mess = 'Some quantities may not have been processed. Check History window.'
    statusBar->update, mess
  endif else if keyword_set(warnnans) then begin 
    message = 'Processing Successful,  but NaNs in data may cause gaps in output.  Check History for more detail.'
    statusBar->update, message 
  endif else begin
    mess = 'Spectra creation successful.'
    statusBar->update, mess
  endelse
  
end
