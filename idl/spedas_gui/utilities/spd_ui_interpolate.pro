;Helper function
;a trial method for nearest neighbour interpolation in cases where you need an irregular grid
; Note: this is the same as the function nearestneighbor in tinterpol_mxn.pro. If you find a bug here
; please fix the other version too.
function spd_ui_nearestneighbor, v, x, u
; v: these are the actual values that will be interpolated (interpolates along one dimension)
; x: these are the x values (probably time) corresponding to the data (v) values (one dim array)
; u: this is the new array of x values, again 1 dim

n_u = n_elements(u)
n_x = n_elements(x)

;-------------------------------------------------------------------------------------
;Method 1: should work even if x is not monotonically incr. But can be very slow or
;run out of memory for large arrays
;-------------------------------------------------------------------------------------
;;this puts into the variable index the index of the closest value in x to each value in u
;; the resulting index is a one-dim subscript of a 2-dim array and thus must be manipulated further
;mindiff = min(abs(rebin(x,n_x,n_u) - rebin(transpose(u),n_x,n_u)),index,dimension=1)
;; convert index to multidim subscript
;index2d = array_indices([n_x,n_u],index,/dimensions)
;; only the first column of index2d is useful, containing index into x of nearest neigbor to each point in u
;; second column is just 0,1,2,3,..etc
;actualindex = transpose(index2d[0,*])

;-------------------------------------------------------------------------------------
;Method 2: only works if x is monotonically increasing or decreasing (same is true for interpol)
;Should be faster than above method for large arrays.
;-------------------------------------------------------------------------------------
;value_locate brackets each u in x
nearvalue = transpose(value_locate(x,u))
neararray = [nearvalue>0, (nearvalue+1)<(n_x-1)]; form an array with columns nearvalue and nearvalue +1, but restrict to valid indices into n_x
mindiff = min(abs(x[neararray]-rebin(transpose(u),2,n_u)),index, dimension=1)
; index gives you the (1 dim) index in neararray, indicating whether nearvalue or nearvalue+1 is closer
; the mod converts simply to 0 or 1
actualindex = transpose(nearvalue>0 + (index mod 2))


output = v[actualindex]
return, output
end

;helper function
;Does the actual interpolation on one N-dimensional quantity(but only interpolating along dimension 1)
;Function is originally from tinterpol_mxn
function spd_ui_interpolate_vec_mxn,v,x,u,nearest_neighbor=nearest_neighbor,_extra=_extra

compile_opt idl2, hidden

n = n_elements(u)

if n le 0 then return,-1L

;if the value is atomic return it
if(size(v,/n_dim) eq 0) then begin 
    error=1
    return,replicate(v,n_elements(u))
endif

v_s = size(v,/dimensions)

;handle single input case...it should extrapolate a constant matrix
if(v_s[0] eq 1) then begin
    v_s[0] = 2
    v = rebin(v,v_s)
    x = rebin([x],2)
    x[1] = x[0] + 1.0 ;so the timeseries ascends
endif

;I think I actually handled the 1 case generally
;if(n_elements(v_s) eq 1) then return,interpol(v,n)

v_s_o = v_s

v_s_o[0] = n

out = dindgen(v_s_o)

;the transpose and the reverse make the indexing scheme work out
;cause the in variables(and tplot variables) work more or less in row
;row major, but idl indexes column major
out_idx = transpose(lindgen(reverse(v_s_o)))

in_idx = transpose(lindgen(reverse(v_s)))

;calculate the number of elements in each matrix/vectors/whatever

product = 1

if n_elements(v_s) gt 1 then begin
  product = product(v_s[1:*])
endif

;for i = 1,n_elements(v_s) - 1L do begin
;
;    product *= v_s[i]
;
;endfor

for i = 0,product-1L do begin

    idx1 = where((out_idx mod product) eq i)
    idx2 = where((in_idx mod product) eq i)

    if(size(idx1,/n_dim) eq 0 || $
       n_elements(idx1) ne n || $
       size(idx2,/n_dim) eq 0 || $
       n_elements(idx2) ne v_s[0]) $
       then return, -1L

    if not keyword_set(u) then begin
      if keyword_set(nearest_neighbor) then begin
        out[idx1] = congrid( v[idx2],n)
      endif else out[idx1] = interpol(v[idx2],n,_extra=_extra) 
    endif else begin
      if keyword_set(nearest_neighbor) then begin
        out[idx1] = spd_ui_nearestneighbor(v[idx2],x,u)
      endif else out[idx1] = interpol(v[idx2],x,u,_extra=_extra)
    endelse

endfor
; for nearest neighbor case cast the output type to the input type
; This is so that if you interpolate bit-packed data you will still be
; able to use bitplot to plot it. It may be that all data should be cast
; to its input type - or maybe not.
if keyword_set(nneigbor) then begin
  out = fix(out, type=size(v, /type))
endif
return,out

end



;+
;NAME:
;  spd_ui_interpolate
;
;PURPOSE:
;  Interpolates over x-axis of active data and adds new data to
;  loaded data object.  Intended to be called from spd_ui_dproc.
;
;CALLING SEQUENCE:
;  spd_ui_interpolate, result, loadedData, historywin, statusbar
;
;INPUT:
;  loadedData: Loaded data object.
;  historywin: History window reference.
;  statusbar: Status bar reference.
;  guiid: If set and valid, will make user queries part of GUI widget hierarchy.
;  result: Anonymous structure returned by spd_ui_interpol_options:
;          {
;           num: Number of points for the result when not matching.
;           cad: Cadence of the result when using that option
;           match: Flag indicating to interpolate to another variable's abcissa.
;           matchto: Group name of variable to match to.
;           extrap: Flags for extrapolation type: [none, last value, NaN]
;           suffix: Suffix to create new data group with.
;           limit: Flag indicating time limits.
;           trange: Time range array containing desired time limits.
;           type: Flags for interpolation type: [linear,quadratic,lsquadratic,spline]
;           ntype: Flag to use number or cadence (0,1 respectively)
;           ok: (not used) Indicates spd_ui_interpol_options was successful
;           }
;
;HISTORY:
;
;-

pro spd_ui_interpolate, result,in_vars, loadedData, historywin, statusbar, $
                        fail=fail, guiid=guiid, _extra=_extra, replay=replay, $
                        overwrite_selections = overwrite_selections, $
                        cadence_selections = cadence_selections
    compile_opt idl2

  catch, on_err
  if on_err ne 0 then begin
    catch, /cancel
    help, /last_message, output=msg
    for i=0, n_elements(msg)-1 do historywin->update,msg[i]
    ok = error_message('Error in Interpolate function. Interpolation halted.', $
                       /center,/noname,title='Interpolation Error')
    fail=1
    return
  endif
  
  if ~keyword_set(guiId) then begin
    guiId = 0
  endif


active_data = in_vars


;Initializations
fail=0b
new_active=''
skipped=''
_extra = {QUADRATIC:result.type[1], $
          LSQUADRATIC:result.type[2], $
          SPLINE:result.type[3]}
nearest_neighbor = result.type[4] 

overwrite_selection = ''
cadence_selection= ''

overwrite_count = 0
cadence_count = 0

if undefined(replay) then begin
    overwrite_selections = ''
    cadence_selections = ''
endif

;Loop over active data
for j=0, n_elements(active_data)-1 do begin

  ;Get data elements
  loadedData->getvardata, name=active_data[j], $
                          time = t, $
                          data = d, $
                          yaxis = yd, $
                          dlimit=dl, $
                          limits=l
      
  if ~ptr_valid(t) || ~ptr_valid(d) then begin
    warning_message = active_data[j] + 'is invalid please re-try'
    ok = spd_ui_prompt_widget(guiId,statusbar,historywin,promptText=warning_message,title='Interpolate error', frame_attr=8)
    ;fail = 1
    continue
  endif 
      
  if ptr_valid(dl) then begin
    dlimit = *dl
  endif 
  
  if ptr_valid(l) then begin
    limit = *l
  endif

  ydata = ptr_valid(yd) ? 1b:0b

  ;Get time restrictions
  n_t = n_elements(*t)
  if result.limit[0] ne 0 then begin
    t0 = result.trange[0]
    t1 = result.trange[1]
  endif else begin
    t0 = (*t)[0]
    t1 = (*t)[n_t-1]
  endelse
  
  if result.limit[0] ne 0 then begin
    ;Apply time limits 
    idx = where( ((*t) ge result.trange[0]) and ((*t) le result.trange[1]), c)
    if c eq 0 then begin
      warning_message = 'No data in selected range for ' + active_data[j] + ' please re-try'
      ok = spd_ui_prompt_widget(guiId,statusbar,historywin,promptText=warning_message,title='Interpolate error', frame_attr=8)
      ;fail = 1
      continue
    endif
    ;Ensure first point ousite the time range is included
    if idx[0] gt 0 then idx = [ idx[0]-1, [idx] ]
    if idx[n_elements(idx)-1] lt (n_t-1) then idx = [ [idx], idx[n_elements(idx)-1]+1 ]  
  endif else begin
    idx = lindgen(n_t)
  endelse


  ;Check for matching
  ;----------
    if result.match[0] ne 0 then begin

;      if result.matchto[0] eq active_data[j] then begin
;        statusbar->update,'Skipping '+active_data[j]+', cannot match to same quantity.'
;        continue
;      endif else 
      
      statusbar->update,'Interpolate: Matching to '+result.matchto[0]+'...'

      ;Get new abscissa for interpol function
      loadedData->getvardata, name=result.matchto[0], time = u
     
      ;apply limit to matching variable if user limit is set, or if extrapolation is turned off
      if result.extrap[0] ne 0 || result.limit[0] ne 0 then begin
      
       ;Apply time limits to result's abcissa
        idxu = where( ((*u) ge t0) and ((*u) le t1), c)
        if c eq 0 then begin
          ok = error_message('No data to match in selected range, please re-try', $
                       /center,/noname,traceback=0, title='Interpolate error')
  ;        fail = 1
          skipped = [skipped,active_data[j]]
          continue
        endif
        
        t_p = (*u)[idxu]
      endif else begin
        t_p = (*u)
      endelse
      
      d_p = spd_ui_interpolate_vec_mxn(*d,*t,t_p,nearest_neighbor=nearest_neighbor,_extra=_extra)
      
      if ydata eq 1 then begin
       yd_p = spd_ui_interpolate_vec_mxn(*yd,*t,t_p,nearest_neighbor=nearest_neighbor,_extra=_extra)
      endif
        
      if result.extrap[0] eq 0 then begin
      
        ;find out of range indices to be extrapolated
        if result.limit[0] ne 0 then begin     
          low_idx = where(t_p lt t0,low_c)
          high_idx = where(t_p gt t1,high_c)
        endif else begin
          low_idx = where(t_p lt (*t)[0],low_c)
          high_idx =  where(t_p gt (*t)[n_t-1],high_c)
        endelse
        
        ;extrapolate low end indices
        if low_c gt 0 then begin
          if result.extrap[1] ne 0 then begin ;extrapolate by repetition
            d_p[low_idx,*] = (*d)[0,*] ## (dblarr(low_c)+1)
            if ydata eq 1 then begin
              yd_p[low_idx,*] = (*yd)[0,*] ## (dblarr(low_c)+1)
            endif
          endif else if result.extrap[2] ne 0 then begin ;extrapolate with nans
            d_p[low_idx,*] = !VALUES.D_NAN
;            if ydata eq 1 then begin ;we probably don't want this
;              yd_p[low_idx,*] = !VALUES.D_NAN
;            endif
          endif
        endif
        
        ;extrapolate high end indices
        if high_c gt 0 then begin
          if result.extrap[1] ne 0 then begin ;extrapolate by repetition
            d_p[high_idx,*] = (*d)[n_t-1,*] ## (dblarr(high_c)+1)
            if ydata eq 1 then begin
              yd_p[high_idx,*] = (*yd)[n_t-1,*] ## (dblarr(high_c)+1)
            endif
          endif else if result.extrap[2] ne 0 then begin ;extrapolate with nans
            d_p[high_idx,*] = !VALUES.D_NAN
;            if ydata eq 1 then begin ;we probably don't want this
;              yd_p[high_idx,*] = !VALUES.D_NAN
;            endif
          endif
        endif
        
      endif
      
  
  ;Check if using Cadence
  ;---------
    endif else if result.ntype[0] then begin


      statusbar->update,'Interpolate: Using '+strtrim(result.cad[0])+' second cadence...'


      n_d0 = n_elements((*d)[idx,0])
      n_d1 = n_elements((*d)[0,*])
      if ydata then begin
        n_yd1 = n_elements((*yd)[0,*])
      endif

      ;Create new abcissa at desired cadence
      n_u = floor( (t1-t0)/result.cad[0],/l64)

      u = result.cad[0]*dindgen(n_u) + t0

      ;Check requested resolution
      if n_d0 gt n_u then begin
          if cadence_selection ne 'yestoall' then begin
                if cadence_selection eq 'notoall' then continue
                
                cadence_selection = ''
                if ~undefined(replay) then begin
                    if cadence_count gt n_elements(cadence_selections) then begin
                        dprint, dlevel = 0, 'Error: discrepancy in SPEDAS document, may have led to a document load error'
                        cadence_selection = 'yestoall'
                    endif else begin
                        cadence_selection = cadence_selections[cadence_count]
                    endelse
                endif else begin
                    prompt = 'Using the requested cadence  ('+strtrim(result.cad[0],2)+ $
                             ' sec) will decrease time resolution for '+active_data[j]+ $
                             ' .  Proceed?'
                    cadence_selection = spd_ui_prompt_widget(guiId,statusbar,historywin,promptText=prompt,$
                                              /yes,/no,/allyes,/allno,title='Decrease time resolution?', frame_attr=8)
                    cadence_selections = array_concat_wrapper(cadence_selection, cadence_selections)
                endelse
                
                cadence_count++
                if (cadence_selection eq 'no' || cadence_selection eq 'notoall') then continue
          endif
      endif

      ;Do interpolation
      ;-----------
      d_p = dblarr( n_u, n_d1, /nozero)
      for i=0, n_d1-1 do begin
        if nearest_neighbor eq 1 then begin 
          d_p[0,i] = congrid( (*d)[idx,i],n_u)
        endif else d_p[0,i] = interpol( (*d)[idx,i], (*t)[idx], (u), _extra=_extra )
      endfor

      ;Interpolate over any yaxis data
      ;-----------
      if ydata then begin
        yd_p = dblarr( n_u, n_yd1, /nozero)
        for i=0, n_yd1-1 do begin
          if nearest_neighbor eq 1 then begin
            yd_p[0,i] = congrid( (*yd)[idx,i],n_u)
          endif else yd_p[0,i] = interpol( (*yd)[idx,i], (*t)[idx], (u), _extra=_extra )
        endfor
      endif

      t_p = temporary(u)

  ;If not, use default option
  ;---------
    endif else begin

      statusbar->update,'Interpolate: Using '+strtrim(result.num[0])+' points...'

      n_d0 = n_elements((*d)[idx,0])
      n_d1 = n_elements((*d)[0,*])
      if ydata then begin
        n_yd1 = n_elements((*yd)[0,*])
      endif

      ;Create new x-axis explicitly
      u = interpol( [t0,t1], result.num[0])
      
      ;Check requested resolution
      if n_d0 gt result.num[0] then begin
          if cadence_selection ne 'yestoall' then begin
                if cadence_selection eq 'notoall' then continue
                
                cadence_selection = ''
                if ~undefined(replay) then begin
                    if cadence_count gt n_elements(cadence_selections) then begin
                        dprint, dlevel = 0, 'Error: discrepancy in SPEDAS document, may have led to a document load error'
                        cadence_selection = 'yestoall'
                    endif else begin
                        cadence_selection = cadence_selections[cadence_count]
                    endelse
                endif else begin
                    prompt = 'The requested number of data points is less than '+$
                             'the current data resolution for '+active_data[j]+ $
                             ' ( '+strtrim(n_d0,2)+' points).  Proceed?'
                    cadence_selection = spd_ui_prompt_widget(guiId,statusbar,historywin,promptText=prompt,$
                                              /yes,/no,/allyes,/allno,title='Decrease time resolution?', frame_attr=8)
                    cadence_selections = array_concat_wrapper(cadence_selection, cadence_selections)
                endelse
                
                cadence_count++
                if (cadence_selection eq 'no' || cadence_selection eq 'notoall') then continue
          endif
      endif

      ;Do interpolation
      ;-----------
      d_p = dblarr(result.num[0], n_d1, /nozero)
      for i=0, n_d1-1 do begin
        if nearest_neighbor eq 1 then begin
          d_p[0,i] = congrid( (*d)[idx,i], result.num[0])
        endif else d_p[0,i] = interpol( (*d)[idx,i], (*t)[idx], u, _extra=_extra)
      endfor

      ;Interpolate over any yaxis data
      ;----------- 
      if ydata then begin
        yd_p = dblarr(result.num[0], n_yd1, /nozero)
        for i=0, n_yd1-1 do begin
          if nearest_neighbor eq 1 then begin
            yd_p[0,i] = congrid( (*yd)[idx,i], result.num[0])
          endif else yd_p[0,i] = interpol( (*yd)[idx,i], (*t)[idx], u, _extra=_extra)
        endfor
      endif

      t_p = temporary(u)

    endelse


    ;Set up data to be added
    name = active_data[j]+result.suffix[0]
    if ptr_valid(l) then limit = *l else limit=0 
    if ptr_valid(dl) then dlimit = *dl else dlimit=0
    if ydata then data = {x:temporary(t_p), y:temporary(d_p), v:temporary(yd_p)} $
      else data = {x:temporary(t_p), y:temporary(d_p)}

    ; check if the new tplot variable already exists, query the user to overwrite it if it does
    spd_ui_check_overwrite_data,name,loadedData,guiId,statusBar,historyWin,overwrite_selection,overwrite_count,$
                             replay=replay,overwrite_selections=overwrite_selections
    if strmid(overwrite_selection, 0, 2) eq 'no' then continue

    ; Add data
    add = loadedData->addData(name, data, dlimit=dlimit, limit=limit, isspect=ydata)
    if add then new_active = [new_active,name] $
      else skipped = [skipped,active_data[j]]

endfor


;Reset active data quantities
  if n_elements(new_active) gt 1 then begin
    loadedData->clearAllActive
    for i=1, n_elements(new_active)-1 do loadedData->setactive,new_active[i]
  endif

;Return messages for any problems encountered
  if fail then begin
    statusbar->update,'Interpolate:  One or more problems occured. See history.'
  endif else begin
    statusbar->update,'Interpolate: Successful'
  endelse

  if n_elements(skipped) gt 1 then begin
    for i=1, n_elements(skipped)-1 do begin
      historywin -> update, skipped[i]+' not processed.'
    endfor
    statusbar->update, 'Interpolate: Some quantities were not processed. See history.'
  endif


end
