;+
;Procedure:
;  thm_ui_cotrans_options
;
;Purpose:
;  Gets and returns information required to perform THEMIS
;  coordinate transforms in the SPEDAS GUI.
;  This is the setup routine for thm_ui_cotrans and the 
;  routine explicitly listed in the plugin text file.
;
;Calling Sequence:
;  Called internally by SPEDAS
;
;API Input:
;  gui_id:  Top level widget ID needed for building new windows
;  
;  status_bar:  SPEDAS GUI status bar object
;  history_window:  SPEDAS GUI history window object  
;
;  loaded_data:  SPEDAS loaded data object.
;                Used to check necessity of loading THEMIS support data.  
;  
;API Output:
;  plugin_structure:  Custom output structure used to pass information to
;                     plugin's primary routine (thm_ui_cotrans).
;
;Notes:
;  This routine is for setup only.  Any action needed to replay the
;  requested operation must occur in the primary routine (thm_ui_cotrans)
;  instead of here.  This includes:
;    -adding to or editing the GUI's loaded data
;    -loading support data or other necessary tplot variables 
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-05-22 16:55:11 -0700 (Fri, 22 May 2015) $
;$LastChangedRevision: 17684 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spedas_plugin/thm_ui_cotrans/thm_ui_cotrans_options.pro $
;
;-

function thm_ui_cotrans_options, $
                        loaded_data=loaded_data, $
                        
                        gui_id=gui_id, $
                        status_bar=sb, $
                        history_window=hw, $
                        
                        plugin_structure=plugin_structure, $

                        _extra=_extra


  compile_opt idl2, hidden


;get names of active vars
active = loaded_data->getActive(/parent)

if ~keyword_set(active) then begin
  spd_ui_message, 'No active data to transform', sb=sb
  return, {ok:0b}
endif


out_coord = strlowcase(strtrim(plugin_structure.name,2))


;initialize output
;--------------------------------------------------
support_parameters = { valid:0b, $
                       probe:'', $
                       in_coord:'', $
                       trange:[0d,0], $
                       load_state:0b, $
                       load_slp:0b }
support_parameters = replicate(support_parameters, n_elements(active))


output = { ok: 0b, $
           process_all_vars_at_once:1b, $
           dproc_routine: 'thm_ui_cotrans', $
           keywords: { out_coord:'', $
                       support_parameters:support_parameters } $
          }


;for error reporting
error_title = 'Coordinate Transform Error'

;initialize user prompt output
load_state = ''
load_slp = ''


;loop over active data to check for requisite support data
;--------------------------------------------------
for i = 0,n_elements(active)-1 do begin

  ;get metadata from current variable
  ;--------------------------------------------------
  loaded_data->getVarData, name=active[i], $
                           data=data, $
                           mission=mission, $
                           observatory=probe, $
                           coordsys=in_coord, $
                           trange=trange
    

  ;various checks
  ;--------------------------------------------------
  ;set dummy probe for non-THEMIS data
  if strlowcase(mission) ne 'themis' then begin
    probe='x'
  endif
  
  ;skip if variable has no coord system
  if strlowcase(in_coord) eq 'n/a' then begin
    errors = array_concat(active[i] + ':  Data has no defined coordinate system.', errors)
    continue
  endif
  
  ;skip if variable is not a 3-vector
  ;copying the data to do this check here is inefficient, perhaps it should be done elsewhere
  dDim = dimen(*data)
  if n_elements(dDim) ne 2 || dDim[1] ne 3 then begin
    errors = array_concat(active[i] + ':  Data is not a 3-vector.', errors)
    continue
  endif

  ;parse long probe names
  if stregex(probe, '^th[abcde]|xxx$', /fold_case, /bool) then begin
    probe = strlowcase(strmid(probe,2,1))
  endif

  ;check probe ("x" may be used as placeholder for non-THEMIs data)
  if ~stregex(probe, '^[abcdex]$', /bool) then begin
    errors = array_concat('Invalid spacecraft designation: '+probe, errors)
    continue
  endif
  
  ;skip if themis specific transform is requested for non-themis data
  if probe eq 'x' then begin
    if in_set(in_coord, ['spg','dsl','ssl']) || in_set(out_coord, ['spg','dsl','ssl']) then begin
      errors = array_concat(active[i] + ':  Cannot convert non THEMIS data to SPG, DSL, or SSL coordinates.', errors)
      continue
    endif
  endif
  
  ;check for EFI variables and disallow coordinate transforms from SPG to anything else
  efi_vars = ['eff', 'efp', 'efw']
  efi_test = where(strmid(active[i], 4, 3) Eq efi_vars)
  if(efi_test[0] ne -1 &&  strlowcase(in_coord) eq 'spg') then begin
    errors = array_concat(active[i] + ':  EFI data in SPG cannot be transformed.'+ $
                          ' Please load EFI L1 data in DSL instead.', errors)
    continue
  Endif


  ;check if state data is required for transform
  ;--------------------------------------------------
  if thm_ui_req_spin(in_coord,out_coord,probe,trange) then begin
     
    message_stem = 'Required state data (probe '+probe+' not loaded for transform of ' + active[i]
    skip_message = message_stem + '; skipping.' 
    prompt_message = message_stem + '.  Would you like to load this data automatically?'
    
    if load_state ne 'yestoall' && load_state ne 'notoall' then begin
      load_state = spd_ui_prompt_widget(gui_id,sb,hw,promptText=prompt_message,title="Load state data?",defaultValue="no",/yes,/no,/allyes,/allno, frame_attr=8)
    endif
    
    if load_state eq 'notoall' || load_state eq 'no' then begin
      spd_ui_message, skip_message, sb=sb, hw=hw 
      continue
    endif
    
    if load_state eq 'yes' || load_state eq 'yestoall' then begin
      support_parameters[i].load_state = 1b
    endif

  endif
  

  ;check if slp data is required for transform
  ;--------------------------------------------------
  if thm_ui_req_slp(in_coord,out_coord,trange) then begin
    
    message_stem = 'Required Solar/Lunar ephemeris not present for transform of ' + active[i]
    skip_message = message_stem + '; skipping.' 
    prompt_message = message_stem + '.  Would you like to load this data now?'
    
    if load_slp ne 'yestoall' && load_slp ne 'notoall' then begin
      load_slp = spd_ui_prompt_widget(gui_id,sb,hw,promptText=prompt_message,title="Load SLP data?",defaultValue="no",/yes,/no,/allyes,/allno, frame_attr=8)  
    endif
     
    if load_slp eq 'notoall' || load_slp eq 'no' then begin
      spd_ui_message, skip_message, sb=sb, hw=hw 
      continue
    endif

    if load_slp eq 'yes' || load_slp eq 'yestoall' then begin
      support_parameters[i].load_slp = 1b
    endif

  endif


  ;set remaining flags
  ;--------------------------------------------------
  support_parameters[i].probe = probe
  support_parameters[i].in_coord = in_coord
  support_parameters[i].trange = trange
  support_parameters[i].valid = 1b


endfor


;report skipped variables and return dproc structure
;--------------------------------------------------
if ~undefined(errors) then begin
  text = ['Some errors were encountered; the following data was not transformed:  ',errors]
  spd_ui_message, strjoin(text,ssl_newline()), title='Skipped variables', /dialog, hw=hw
endif

output.keywords.support_parameters = support_parameters
output.keywords.out_coord = out_coord
output.ok = total(support_parameters.valid) gt 0

return, output


end
