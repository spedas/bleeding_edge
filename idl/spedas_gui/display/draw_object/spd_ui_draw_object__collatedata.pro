;+
;spd_ui_draw_object method: collateData
;
;gets data from loadedData, collects into arrays and performs basic preprocessing.
;
;INPUT:
;
;  traces(array of objects): spd_ui_line_settings or spd_ui_spectra_settings, with names of data to be requested
;  loadedData(spd_ui_loaded_data):  The loaded data object from which data will be taken.
;  yscale(long): 0(linear),1(log10),or 2(logN) to indicate the scaling mode used for the y-axis.  This is needed if
;                a dummy y-axis needs to be generated for a spectral plot with no y-data specified.
;                
;OUTPUTS
;  outXPtrs(array of pointers):  An array of pointers containing the extracted X traces
;  outYPtrs(array of pointers):  An array of pointers containing the extracted Y traces
;  outZPtrs(array of pointers):  An array of pointers containing the extracted Z traces(or null pointers if corresponding trace is line)
;  mirror(array of pointers): An array of pointers containing pointers to mirror data(or null pointers if traces is not mirroring)
;  fail(boolean) : 1 if the operation fails, 0 otherwise
;  dataNames(array of strings):  Name of the dependent variable for each trace
;  dataidx(array of indexes):  The indices of traces that are valid after processing, -1 if non are.
; 
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__collatedata.pro $
;-

pro spd_ui_draw_object::collateData,traces,loadedData,yscale=yscale,outXPtrs=outXPtrs,outYPtrs=outYPtrs,outZptrs=outZPtrs,mirror=mirror,fail=fail,dataNames=dataNames,dataidx=dataidx

  compile_opt idl2,hidden
  
  fail=1
  
  ;allocate output processing
  outXPtrs = ptrarr(n_elements(traces))
  outYPtrs = ptrarr(n_elements(traces))
  outZPtrs = ptrarr(n_elements(traces))
  mirror=ptrarr(n_elements(traces))
  dataNames = strarr(n_elements(traces))
  specmask = intarr(n_elements(traces))
  
  ;loop ovr traces
  for i = 0,n_elements(traces)-1 do begin
  
    ;get data names
    traces[i]->getProperty,dataX=dataX,dataY=dataY
    
    ;get copies of the data
    loadedData->getvardata,name=dataX,data=xptr,/duplicate
    loadedData->getvardata,name=dataY,data=yptr,/duplicate
    
    ;handle spectral trace
    if obj_isa(traces[i],'spd_ui_spectra_settings') then begin
      ;get z-name
      traces[i]->getProperty,dataZ=dataZ
      
      ;get z data
      loadedData->getvardata,name=dataz,data=zptr,/duplicate
      
      ;slip spectral with missing data
      if ~ptr_valid(zptr) then continue
      
      d = dimen(*zptr)
      
      ;if y doesn't exist, then create it so that plotting can still be done
      ;The value selected will just space channels evenly.
      if ~keyword_set(dataY) then begin
      
        self.statusBar->update,'Warning: No yaxis quantity is present in spectral plot of: ' + dataZ + '. Y axis will be scaled proportionally.'
        self.historyWin->update,'Warning: No yaxis quantity is present in spectral plot of: ' + dataZ + '. Y axis will be scaled proportionally.'
        
        if n_elements(d) eq 1 then d = [d,1]
        
        ;scale the dummy y-value so that spacing will appear even on spectral plot
        if keyword_set(yscale) && yscale eq 1 then begin
          yvaltemp = 10^dindgen(d[1])
        endif else if keyword_set(yscale) && yscale eq 2 then begin
          yvaltemp = exp(dindgen(d[1]))
        endif else begin
          yvaltemp = dindgen(d[1])
        endelse
        
        yptr = ptr_new(transpose(rebin(yvaltemp,d[1],d[0])))
      endif
      
    endif
    
    ;skip plot with missing data
    if ~ptr_valid(xptr) || ~ptr_valid(yptr) then continue
    
    ;handle line trace specific mods
    if obj_isa(traces[i],'spd_ui_line_settings') then begin
    
      dataNames[i] = dataY
      
      ;find out if we need  mirror line
      traces[i]->getProperty,mirrorLine=mirrorLine
      
      outXptrs[i] = xptr
      
      ;screen y-data
      if ndimen(*yptr) gt 1 then begin
        self.statusBar->update,'Cannot have multi-d y-quantities on line plots'
        self.historyWin->update,'Cannot have multi-d y-quantities on line plots'
        return
      endif
      
      ;store y-data
      if n_elements(*xptr) eq n_elements(*yptr) then begin
        outYptrs[i] = yptr
      endif else begin
      
        self.historyWin->update,'Warning: X axis quantity does not match data quantity for: ' + dataY
        self.statusBar->update,'Warning: X axis quantity does not match data quantity for: ' + dataY
      
        ;if y does not match x, we interpolate them onto the same grid.
        outYptrs[i] = ptr_new(interpol(*yptr,n_elements(*xptr)))
        ptr_free,yptr
      endelse
      
      ;create reflected mirror data
      if mirrorLine then begin
        mirror[i]=ptr_new(-(*outYptrs[i]))
        *mirror[i]=double(*mirror[i])
      endif
      
      ;all data is treated as double precision inside the draw routine
      *outXptrs[i] = double(*outXptrs[i])
      *outYptrs[i] = double(*outYptrs[i])
      
    ;handle spectral settings
    endif else if obj_isa(traces[i],'spd_ui_spectra_settings') then begin
    
      ;this allows us to mask out the spectragrams from our list of traces      
      specmask[i] = 1
      
      dataNames[i] = dataZ
      
      outZptrs[i] = zptr
      
      dim = dimen(*zptr)
      
      ;IDL has an annoying habit of making dimensions disappear.
      ;Ensuring data is 2-d so algorithms work consistently
      if n_elements(dim) eq 1 then begin
        dim = [dim,1]
      endif
      
      ;store x-data
      if dim[0] eq n_elements(*xptr) then begin
        outXptrs[i] = xptr
      endif else begin
       
        self.historyWin->update,'Warning: X axis quantity does not match data quantity for: ' + dataZ
        self.statusBar->update,'Warning: X axis quantity does not match data quantity for: ' + dataZ
      
        ;if x does not match z, we interpolate onto the same grid
        outXptrs[i] = ptr_new(interpol(*xptr,dim[0]))
        ptr_free,xptr
      endelse
      
      dimy = dimen(*yptr)

      ;if the y-dimension is unchanging, we can use a more efficient
      ;draw pipeline

      ;This code block will make the y-axis 1-d, if possible
      if n_elements(dimy) eq 2 then begin      

        ;if the max is the same as the min in all columns
        ;then the value never changes over time
        max_val = max(*yptr,dimension=1,/nan,min=min_val)
        
        ;remove NaNs before performing check
        ;even with the /nan switch, 'max' can have nans in the output
        ;if every data value along a dimension in NaN
        idx = where(finite(max_val),c)
        
        if c ne 0 then begin
          max_val = max_val[idx]
          min_val = min_val[idx]
        endif

        ;if the data is all NaNs or unchanging, then we can clip down to 1d
        if array_equal(max_val,min_val) || c eq 0 then begin
          tmp = ptr_new(reform((*yptr)[0,*]))
          ptr_free,yptr
          yptr=tmp
          dimy = dimen(*yptr)
        endif
        
      endif
        
      ;if the y-axis data doesn't match, interpolate onto the z-grid
      if n_elements(dimy) eq 2 then begin 
        ;if everything matches up, then store the result
        if dim[0] eq dimy[0] && dim[1] eq dimy[1] then begin
          outYptrs[i] = yptr
        endif else begin 
          self.historyWin->update,'Warning: Y axis quantity does not match data quantity for: ' + dataZ
          self.statusBar->update,'Warning: Y axis quantity does not match data quantity for: ' + dataZ
        
         ;otherwise match the elements to the contents of the z-axis data
          outYptrs[i] = ptr_new(interpolate(*yptr,dimy[0]*dindgen(dim[0])/dim[0],dimy[1]*dindgen(dim[1])/dim[1],/grid))
          ptr_free,yptr
        endelse
        
      endif else begin
      
        if dim[1] eq dimy[0] then begin
          outYptrs[i] = yptr
        endif else begin
          outYptrs[i] = ptr_new(interpol(*yptr,dim[1]))
          ptr_free,yptr
        endelse
        
      endelse
        
      
      ;all data is treated as double precision inside the draw routine
      *outXptrs[i] = double(*outXptrs[i])
      *outYptrs[i] = double(*outYptrs[i])
      *outZptrs[i] = double(*outZptrs[i])
      
    endif else begin
      self.statusbar->update,'Error: Draw object was passed illegal trace settings'
      self.historyWin->update,'Error: Draw object was passed illegal trace settings'
      ; ok = error_message('Illegal trace settings passed to draw object',/traceback)
      return
    endelse
    
  endfor
  
  fail = 0
  
  ;construct the list of valid trace indices 
  dataidx = where(ptr_valid(outXptrs) and ptr_valid(outYptrs) and (~specmask or ptr_valid(outZptrs)))
  
end
