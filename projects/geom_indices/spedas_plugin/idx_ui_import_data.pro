;+
;NAME:
;  idx_ui_import_data
;
;PURPOSE:
;  Provides a single interface for accessing the geomagnetic/solar index load routines
;  from the GUI
;
;  
;REVISION HISTORY:
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-16 16:09:24 -0700 (Thu, 16 Apr 2015) $
;$LastChangedRevision: 17344 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/geom_indices/spedas_plugin/idx_ui_import_data.pro $
;-

pro idx_ui_import_data,$
                         loadStruc,$
                         loadedData,$
                         statusBar,$
                         historyWin,$
                         parent_widget_id,$  
                         replay=replay,$
                         overwrite_selections=overwrite_selections
                         

  compile_opt hidden,idl2
  
  ; initialize variables
  loaded = 0
  new_vars = ''
  overwrite_selection=''
  overwrite_count = 0
  mission = 'Geomagnetic Indices'
  
  geom_indices_init  
  local_data_dir=!geom_indices.local_data_dir
  remote_data_dir_noaa=!geom_indices.remote_data_dir_noaa
  remote_data_dir_kyoto_ae=!geom_indices.remote_data_dir_kyoto_ae
  remote_data_rit_kyoto_kp=!geom_indices.remote_data_dir_kyoto_dst
  
  if ~keyword_set(replay) then begin
    overwrite_selections = ''
  endif

  ; extract the variables from the load structure
  index = loadStruc.index
  indextype = loadStruc.datatypes
  resolution = loadStruc.resolution
  timeRange = loadStruc.timerange

  ; tplot variables before loading data
  tn_before = [tnames('*',create_time=cn_before)]

  ntrange = fltarr(2)
  ntrange[0] = time_double(timeRange[0])
  ntrange[1] = time_double(timeRange[1])

  for i = 0, n_elements(indextype)-1 do begin
    ; note that the mission/observatory/instrument variables 
    ; are used to populate the data tree in the load window
    case index of
          'Ap': begin
              observatory = 'NOAA'
              instrument = 'NGDC'
              indexmintime = '1933-01-01'
              indexmaxtime = time_string(systime(/seconds))
              if indextype[i] eq 'ap' then begin
                  datatype = 'ap'
              endif else if indextype[i] eq 'Ap (ap mean)' then begin
                  datatype = 'ap_mean'
              endif else begin ; *
                  datatype = ['ap', 'ap_mean']
              endelse
              noaa_load_kp, trange = ntrange, datatype = datatype, local_kp_dir=local_data_dir, kp_mirror=remote_data_dir_noaa
          end
          'AE': begin
              observatory = 'Kyoto'
              instrument = 'WDC'
              indexmintime = '1957-01-01'
              indexmaxtime = time_string(systime(/seconds))
              if indextype[i] eq 'AE prov' then begin
                  datatype = 'ae'
              endif else if indextype[i] eq 'AO prov' then begin
                  datatype = 'ao'
              endif else if indextype[i] eq 'AU prov' then begin
                  datatype = 'au'
              endif else if indextype[i] eq 'AL prov' then begin
                  datatype = 'al'
              endif else if indextype[i] eq 'AX prov' then begin
                  datatype = 'ax'
              endif else begin ; *
                  datatype = ['ae','ao','au','al','ax']
              endelse
              kyoto_load_ae, trange = ntrange, datatype = datatype, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir_kyoto_ae
          end
          'Cp': begin
              observatory = 'NOAA'
              instrument = 'NGDC'
              indexmintime = '1957-01-01'
              indexmaxtime = time_string(systime(/seconds))
              if indextype eq 'Cp' then begin ; currently the only option for this index
                  datatype = 'cp'
              endif
              noaa_load_kp, trange = ntrange, datatype = datatype, local_kp_dir=local_data_dir, kp_mirror=remote_data_dir_noaa
          end
          'C9': begin
              observatory = 'NOAA'
              instrument = 'NGDC'
              indexmintime = '1957-01-01'
              indexmaxtime = time_string(systime(/seconds))
              if indextype eq 'C9' then begin ; currently the only option for this index
                  datatype = 'c9'
              endif
              noaa_load_kp, trange = ntrange, datatype = datatype, local_kp_dir=local_data_dir, kp_mirror=remote_data_dir_noaa
          end
          'Dst': begin
              observatory = 'Kyoto'
              instrument = 'WDC'
              indexmintime = '1957-01-01'
              indexmaxtime = time_string(systime(/seconds))
              if indextype[i] eq 'Dst prov' then begin
                datatype = 'dst'
              endif else if indextype[i] eq 'Dst final' then begin
                datatype = 'dst'
              endif else if indextype[i] eq 'Dst real-time' then begin
                datatype = 'dst'
              endif else begin ; *
                datatype = ['dst']
              endelse
              kyoto_load_dst, trange = ntrange, datatype = datatype, /apply_time_clip, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir_kyoto_dst
          end
          'F10.7': begin
              observatory = 'NOAA'
              instrument = 'NGDC'
              indexmintime = '1957-01-01'
              indexmaxtime = time_string(systime(/seconds))
              if indextype[i] eq 'F10.7' then begin ; only option for this index
                  datatype = 'f10.7'
              endif
              noaa_load_kp, trange = ntrange, datatype = datatype, local_kp_dir=local_data_dir, kp_mirror=remote_data_dir_noaa
          end
          'Kp': begin
              observatory = 'NOAA'
              instrument = 'NGDC'
              indexmintime = '1933-01-01'
              indexmaxtime = time_string(systime(/seconds))
              if indextype[i] eq 'Kp' then begin
                  datatype = 'kp'
              endif else if indextype[i] eq 'Kp sum' then begin
                  datatype = 'kp_sum'
              endif else begin ; *
                  datatype = ['kp', 'kp_sum']
              endelse
              noaa_load_kp, trange = ntrange, datatype = datatype, local_kp_dir=local_data_dir, kp_mirror=remote_data_dir_noaa
          end
          'Solar rotation #': begin
              observatory = 'NOAA'
              instrument = 'NGDC'
              indexmintime = '1957-01-01'
              indexmaxtime = time_string(systime(/seconds))
              if indextype[i] eq 'Solar rotation #' then begin ; only option for this index
                  datatype = 'sol_rot_num'
              endif 
              noaa_load_kp, trange = ntrange, datatype = datatype, local_kp_dir=local_data_dir, kp_mirror=remote_data_dir_noaa
          end
          'Solar rotation day': begin
              observatory = 'NOAA'
              instrument = 'NGDC'
              indexmintime = '1957-01-01'
              indexmaxtime = time_string(systime(/seconds))
              if indextype[i] eq 'Solar rotation day' then begin ; only option for this index
                  datatype = 'sol_rot_day'
              endif
              noaa_load_kp, trange = ntrange, datatype = datatype, local_kp_dir=local_data_dir, kp_mirror=remote_data_dir_noaa
          end
          'Sunspot #': begin
              observatory = 'NOAA'
              instrument = 'NGDC'
              indexmintime = '1957-01-01'
              indexmaxtime = time_string(systime(/seconds))
              if indextype[i] eq 'Sunspot #' then begin ; only option for this index
                  datatype = 'sunspot_number'
              endif
              noaa_load_kp, trange = ntrange, datatype = datatype, local_kp_dir=local_data_dir, kp_mirror=remote_data_dir_noaa
          end
          'SYM/ASY': begin
              observatory = 'ISTP'
              instrument = 'OMNI'
              indexmintime = '1995-01-01'
              indexmaxtime = time_string(systime(/seconds))
              ; note about kludge:
              ; datatype is used to cull out unwanted OMNI data using strfilter
              ; *sy* will match all SYM/ASY data, but none of the other OMNI variables
              if indextype[i] eq 'Sym-H' then begin
                  datatype = 'sym_h'
              endif else if indextype[i] eq 'Sym-D' then begin
                  datatype = 'sym_d'
              endif else if indextype[i] eq 'Asy-H' then begin
                  datatype = 'asy_h'
              endif else if indextype[i] eq 'Asy-D' then begin
                  datatype = 'asy_d'
              endif else begin ; *
                  datatype = 'sy'
              endelse
              if resolution eq '*' then begin
                  omni_hro_load, trange = timeRange, res1min=1
                  omni_hro_load, trange = timeRange, res5min=1
              endif else begin
                  ; this works because of how omni_hro_load is implemented, i.e.,
                  ; if the keyword res5min is not set, it defaults to 1-min data
                  omni_hro_load, trange = timeRange, res5min=(resolution eq '5-min')
              endelse
              ; filter out unwanted OMNI data
              to_delete = strfilter(tnames(), tnames('*'+strjoin(strsplit(resolution, '-', /extract))+'_*'+strupcase(datatype)+'*'), /NEGATE)
              ; keep the data we're interested in
              new_vars = strfilter(tnames(), tnames('*'+strjoin(strsplit(resolution, '-', /extract))+'_*'+strupcase(datatype)+'*'))
          end
          else: begin
            statusBar->update,'No Geomagnetic Indices Data Loaded'
            historyWin->update,'No Geomagnetic Indices Data Loaded'
          end
    endcase
  endfor

  ; if the time range specified by the user is not within the time range 
  ; of available data for this mission and instrument then inform the user 
  if time_double(indexmaxtime) lt time_double(timerange[0]) || $
     time_double(indexmintime) gt time_double(timerange[1]) then begin
     statusBar->update,'No Geomagnetic Indices Data Loaded, '+index+' data is only available between ' + indexmintime + ' and ' + indexmaxtime
     historyWin->update,'No Geomagnetic Indices Data Loaded, '+index+' data is only available between ' + indexmintime + ' and ' + indexmaxtime
     return
  endif

  ; determine which tplot vars to delete and which ones are the new temporary vars
  if undefined(to_delete) then begin
      spd_ui_cleanup_tplot, tn_before, create_time_before=cn_before, del_vars=to_delete,new_vars=new_vars
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
      result = loadedData->add(new_vars[i],mission=mission,observatory=observatory, $
                               instrument=instrument)

      ; report errors to the status bar and add them to the history window
      if ~result then begin
        statusBar->update,'Error loading: ' + new_vars[i]
        historyWin->update,'Geomagnetic Indices: Error loading: ' + new_vars[i]
        return
      endif
    endfor
  endif
    
  ; remove the temporary tplot variables 
  if to_delete[0] ne '' then begin
     store_data,to_delete,/delete
  endif
  
  ; inform the user that the load was successful and add it to the history   
  if loaded eq 1 then begin  
     statusBar->update,'Geomagnetic Indices Data Loaded Successfully'
     historyWin->update,'Geomagnetic Indices Data Loaded Successfully'
  endif else begin
     statusBar->update,'No Geomagnetic Indices Data Loaded'
     historyWin->update,'No Geomagnetic Indices Data Loaded'
  endelse
end
