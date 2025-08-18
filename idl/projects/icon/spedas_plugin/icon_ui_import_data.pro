;+
;NAME:
;  icon_ui_import_data
;
;PURPOSE:
;  Gui ICON data loader
;
;KEYWORDS:
;
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2019-03-02 16:20:46 -0800 (Sat, 02 Mar 2019) $
;$LastChangedRevision: 26743 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/spedas_plugin/icon_ui_import_data.pro $
;
;-------------------------------------------------------------------

pro icon_ui_import_data,     $
  loadStruc,        $
  loadedData,       $
  statusBar,        $
  historyWin,       $
  parent_widget_id, $
  replay=replay,    $
  overwrite_selections=overwrite_selections

  compile_opt hidden,idl2

  instrument = loadStruc.instrument
  datal1type = loadStruc.datal1type
  datal2type = loadStruc.datal2type
  timeRange = loadStruc.timeRange

  loaded = 0

  iconmintime = '2010-01-01'
  ; allow the user to load data up until the current time
  iconmaxtime = time_string(systime(/seconds))

  new_vars = ''

  overwrite_selection=''
  overwrite_count =0

  if ~keyword_set(replay) then begin
    overwrite_selections = ''
  endif

  ; check that the requested time falls within our valid range
  if time_double(iconmaxtime) lt time_double(timerange[0]) || $
    time_double(iconmintime) gt time_double(timerange[1]) then begin
    statusBar->update,'No ICON Data Loaded, ICON data is only available between ' + iconmintime + ' and ' + iconmaxtime
    historyWin->update,'No ICON Data Loaded, ICON data is only available between ' + iconmintime + ' and ' + iconmaxtime
    return
  endif

  tn_before = [tnames('*',create_time=cn_before)]

  if (strupcase(instrument[0]) eq 'FUV') || (strupcase(instrument[0]) eq 'IVM') || (strupcase(instrument[0]) eq 'EUV') || (strupcase(instrument[0]) eq 'MIGHTI') || (instrument[0] eq '*') then begin
    statusBar->update,'Load ICON Data'
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
  endif else begin
    msg = 'Instrument not found: ' + instrument[0]
    statusBar->update,msg
  endelse

  if undefined(to_delete) then begin
    spd_ui_cleanup_tplot,tn_before,create_time_before=cn_before,del_vars=to_delete,new_vars=new_vars
  endif

  ;ToDo: delete non-needed data
  if (n_elements(new_vars) gt 1) || (n_elements(new_vars) eq 1 && new_vars[0] ne '') then begin
    ga = new_vars
    gn = []
    for i = 0, n_elements(ga)-1 do  begin
      nameadd = 1

      get_data, ga[i], data=d
      dsize = dimen(d.y)
      if (n_elements(dsize) gt 2) || (dsize[0] ne n_elements(d.x)) ||  ~is_num(d.y) then begin
        nameadd = 0
      endif

      if not STRMATCH( ga[i], '*icon*' , /FOLD_CASE ) then nameadd = 0
      ;  if not STRMATCH( ga[i], '*fuv*' , /FOLD_CASE ) then nameadd = 0
      ;  if STRMATCH( ga[i], '*time*' , /FOLD_CASE ) then nameadd = 0
      ;  if STRMATCH( ga[i], '*error*' , /FOLD_CASE ) then nameadd = 0
      ;  if STRMATCH( ga[i], '*raw*' , /FOLD_CASE ) then nameadd = 0
      ;  if STRMATCH( ga[i], '*img*' , /FOLD_CASE ) then nameadd = 0
      ;if STRMATCH( ga[i], '*utc*' , /FOLD_CASE ) then nameadd = 0
      ;if STRMATCH( ga[i], '*covariance*' , /FOLD_CASE ) then nameadd = 0
      ;if STRMATCH( ga[i], '*parameter_names*' , /FOLD_CASE ) then nameadd = 0
      if nameadd eq 1 then gn = [gn, ga[i]] else begin
        dprint, dlevel=1, 'Cannot load variable: ', ga[i]
      endelse
      if ga[i] eq 'ICON_L1_FUVB_LWP_PROF_M3' then begin
        dprint, dlevel=1, 'Here is ICON_L1_FUVB_LWP_PROF_M3'
      endif
      
    endfor
    new_vars = gn
  end

  ;spd_ui_tplot_gui_load_tvars,new_vars,all_names=new_vars,gui_id=event.top

  if (new_vars[0] ne '') && (new_vars[0] ne !null) then begin
    loaded = 1

    ; loop over loaded data
    for i = 0,n_elements(new_vars)-1 do begin

      ; handle possible loading errors, if some variable cannot be loaded, skip it
      catch, errvar
      if errvar ne 0 then begin
        dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
        catch, /cancel
        continue
      endif

      ; check if data is already loaded, if so query the user on whether
      ; they want to overwrite data
      spd_ui_check_overwrite_data,new_vars[i],loadedData,parent_widget_id,statusBar,historyWin,overwrite_selection,overwrite_count,$
        replay=replay,overwrite_selections=overwrite_selections
      if strmid(overwrite_selection, 0, 2) eq 'no' then continue

      ; this statement adds the variable to the loadedData object
      ;if ~keyword_set(curdatatype) then  curdatatype= 'swp'

      result = loadedData->add(new_vars[i],mission='ICON',observatory=instrument[0])

      ; report errors to the status bar and add them to the history window
      if ~result then begin
        statusBar->update,'Error loading: ' + new_vars[i]
        historyWin->update,'ICON: Error loading: ' + new_vars[i]
        return
      endif
    endfor
  endif

  if to_delete[0] ne '' then begin
    store_data,to_delete,/delete
  endif

  if loaded eq 1 then begin
    statusBar->update,'ICON Data Loaded Successfully'
    historyWin->update,'ICON Data Loaded Successfully'
  endif else begin
    statusBar->update,'No ICON Data Loaded'
    historyWin->update,'No ICON Data Loaded'
  endelse

end
