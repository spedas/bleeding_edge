;+
;NAME:
;  barrel_ui_import_data
;
;PURPOSE:
;  Modularized GUI data loader for BARREL
;
;Notes:
;
;   Data is loaded using barrel_load_data
;   barrel_load_data downloads data from http://barreldata.ucsc.edu/data_products/
;   October 2014: only v00 is available for the 2013-14 campaign year, this might change in the future
;   
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2016-07-01 10:25:55 -0700 (Fri, 01 Jul 2016) $
;$LastChangedRevision: 21422 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/barrel/spedas_plugin/barrel_ui_import_data.pro $
;
;--------------------------------------------------------------------------------

pro barrel_ui_import_data,     $
  loadStruc,        $
  loadedData,       $
  statusBar,        $
  historyWin,       $
  parent_widget_id, $
  replay=replay,    $
  overwrite_selections=overwrite_selections

  compile_opt hidden,idl2

  campaignyear = loadStruc.campaignyear
  probe = loadStruc.probe
  datatype = loadStruc.datatype
  timeRange = loadStruc.timeRange

  instrument = dataType
  loaded = 0

  barrelmintime = '2013-01-01'
  barrelmaxtime = '2013-02-16'
; removed barrel_version, all are version 5 now, and handled by
; barrel_load_data, jmm, 2016-07-01
;  barrel_version = 'v02' ; v02 data is available for the 2012-13 campaign year
  errmsg = 'No BARREL Data Loaded, BARREL data for 2012-2013 is only available between ' + barrelmintime + ' and ' + barrelmaxtime
  if campaignyear eq '2013-2014' then begin
    barrelmintime = '2013-12-27'
    barrelmaxtime = '2014-02-11'
;    barrel_version = 'v00' ; only v00 data is available for the 2013-14 campaign year
    errmsg = 'No BARREL Data Loaded, BARREL data for 2013-2014 is only available between ' + barrelmintime + ' and ' + barrelmaxtime
  end

  if probe[0] eq '*' then probe = '*'
  if datatype[0] eq '*' then datatype = '*'
  
  new_vars = ''

  overwrite_selection=''
  overwrite_count =0

  if ~keyword_set(replay) then begin
    overwrite_selections = ''
  endif

  ; check that the requested time falls within our valid range
  if time_double(barrelmaxtime) lt time_double(timerange[0]) || $
    time_double(barrelmintime) gt time_double(timerange[1]) then begin
    statusBar->update, errmsg
    historyWin->update, errmsg
    return
  endif

  tn_before = [tnames('*',create_time=cn_before)]

  barrel_load_data, trange = timeRange, probe = probe, datatype = datatype, level=level;, version=barrel_version


  if undefined(to_delete) then begin
    spd_ui_cleanup_tplot,tn_before,create_time_before=cn_before,del_vars=to_delete,new_vars=new_vars
  endif

  if new_vars[0] ne '' then begin
    loaded = 1

    ; loop over loaded data
    for i = 0,n_elements(new_vars)-1 do begin

      ; check if data is already loaded, if so query the user on whether
      ; they want to overwrite data
      spd_ui_check_overwrite_data,new_vars[i],loadedData,parent_widget_id,statusBar,historyWin,overwrite_selection,overwrite_count,$
        replay=replay,overwrite_selections=overwrite_selections
      if strmid(overwrite_selection, 0, 2) eq 'no' then continue

      ; this statement adds the variable to the loadedData object
      result = loadedData->add(new_vars[i])

      ; report errors to the status bar and add them to the history window
      if ~result then begin
        statusBar->update,'Error loading: ' + new_vars[i]
        historyWin->update,'BARREL: Error loading: ' + new_vars[i]
        return
      endif
    endfor
  endif

  if to_delete[0] ne '' then begin
    store_data,to_delete,/delete
  endif

  if loaded eq 1 then begin
    statusBar->update,'BARREL Data Loaded Successfully'
    historyWin->update,'BARREL Data Loaded Successfully'
  endif else begin
    statusBar->update,'No BARREL Data Loaded'
    historyWin->update,'No BARREL Data Loaded'
  endelse

end
