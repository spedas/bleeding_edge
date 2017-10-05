;+
;Procedure:
;  thm_ui_cotrans
;
;Purpose:
;  Perform coordinate transforms for THEMIS dproc plugin.
;  This is the primary routine which loads support data
;  as requested and calls thm_cotrans to perform the 
;  transformation.
;
;Calling Sequence:
;  Called internally by SPEDAS 
;
;API Input:
;  active_data:  List of of tplot vars exported from the GUI for processing  
;
;  support_parameters:  Structure containing options from the setup routine (thm_ui_cotrans_options)
;
;  status_bar:  SPEDAS GUI status bar object
;  history_window:  SPEDAS GUI history window object  
;
;  _extra keyword also required by API
;
;API Output:
;  output_names:  List of tplot variables to be loaded into the GUI on completion.
;  support_names:  List of support data to be left as tplot variables.
;                  All other new tplot variables will be deleted on completion
;
;Notes:
;  This routine executes the core of the operation and should be replayable
;  without required user input.  To that end, any user querries should be
;  placed in the setup routine (thm_ui_cotrans_options).
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-04-24 18:45:02 -0700 (Fri, 24 Apr 2015) $
;$LastChangedRevision: 17429 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spedas_plugin/thm_ui_cotrans/thm_ui_cotrans.pro $
;
;-

pro thm_ui_cotrans, active_data, $
                    
                    output_names=output_names, $
                    support_names=support_names, $
                    
                    status_bar=sb, $
                    history_window=hw, $

                    out_coord=out_coord, $
                    support_parameters=support_parameters, $
                    
                    _extra=_extra

  compile_opt idl2, hidden


error_title = 'Coordinate Transform Error'

;nothing to do if there's no active data
if ~is_string(/blank, active_data) then begin
  spd_ui_message, 'Cannot determine data intended for transformation', sb=sb, hw=hw, /dialog, title=error_title  
  return
endif


;probably an error in thm_ui_cotrans_options if these do not match
if n_elements(active_data) ne n_elements(support_parameters) then begin
  spd_ui_message, 'Number of support data paremeters do not match active data', sb=sb, hw=hw, /dialog, title=error_title 
  return
endif


;initilize input to thm_cotrans
out_suffix = '_'+strlowcase(out_coord)


;Loop over active data variables
;  -load support_data as needed
;--------------------------------------------
for i=0, n_elements(active_data)-1 do begin

  undefine, out_var ;reset output list

  probe = support_parameters[i].probe
  trange = support_parameters[i].trange
  in_coord = support_parameters[i].in_coord

  ;names of support vars
  state_names = ['th'+probe+'_state_spinras', $
                 'th'+probe+'_state_spindec', $
                 'th'+probe+'_state_spinras_corrected', $
                 'th'+probe+'_state_spindec_corrected']

  slp_names = ['slp_sun_pos', $
               'slp_lun_pos', $
               'slp_lun_att_x', $
               'slp_lun_att_z']


  ;load state data if needed/requested
  ;--------------------------------------------
  if support_parameters[i].load_state && thm_ui_req_spin(in_coord, out_coord, probe, trange) then begin

    thm_load_state, probe=probe, trange=trange, /get_support_data
    
    if thm_ui_req_spin(in_coord, out_coord, probe, trange) then begin
      error_message = 'Failed to auto-load state data for THEMIS ' + strlowcase(probe) + ' to transform ' + active_data[i] + "; skipping."
      spd_ui_message, error_message, sb=sb, hw=hw, /dialog, title=error_title
      continue
    endif
    
    ;add to list of tplot variables allowed to persist after returning
    support_names = array_concat(state_names,support_names)

  endif


  ;load slp data if needed/requested
  ;--------------------------------------------
  if support_parameters[i].load_slp && thm_ui_req_slp(in_coord, out_coord, trange) then begin

    thm_load_slp, datatype='all', trange=trange

    if thm_ui_req_slp(in_coord, out_coord, trange) then begin
      error_message = 'Failed to auto-load Solar/Lunar ephemeris to transform ' + active_data[i] + '; skipping.'
      spd_ui_message, error_message, sb=sb, hw=hw, /dialog, title=error_title 
      continue
    endif
  
    ;add to list of tplot variables allowed to persist after returning
    support_names = array_concat(slp_names,support_names)

  endif


  ;parse input name for coordinate suffix
  ;-------------------------------------------
  suffix_pos = stregex(active_data[i],'_'+in_coord+'$', /fold_case)
  if suffix_pos ne -1 then begin
    name = strmid(active_data[i],0,suffix_pos)
    in_suffix = '_'+strlowcase(in_coord)
  endif else begin
    name = active_data[i]
    in_suffix = ''
  endelse


  ;perform transform
  ;--------------------------------------------
  catch, transform_error
  
  if transform_error ne 0 then begin
    catch, /cancel
    help, /last_message, output=last_error
    print, last_error
    spd_ui_message, last_error, hw=hw
    spd_ui_message, 'Unexpected error occured; transform canceled.  See console for details.',sb=sb, hw=hw
    ;clear output lists
    ;  -ensures extra tplot vars from incomplete transfrorms are removed
    ;  -keeps this operation from being added to the call sequence
    undefine, output_names
    undefine, support_names
    return
  endif else begin
  
    thm_cotrans, name, $
                 probe=probe, $
                 in_coord=in_coord, $
                 out_coord=out_coord, $
                 in_suffix=in_suffix, $
                 out_suffix=out_suffix, $
                 out_vars=out_var
  
  endelse
  
  catch, /cancel

  
  ;check that transformation succeeded and add new data to output list
  ;-------------------------------------------
  if keyword_set(out_var) then begin
    spd_ui_message, 'Successfully transformed '+active_data[i]+' to: ' + out_var[0], sb=sb, hw=hw

    ;output transformed data
    output_names = array_concat(out_var[0], output_names)

  endif else begin
    spd_ui_message, 'Data not transformed: '+active_data[i], sb=sb, hw=hw
    continue
  endelse
  

endfor


end