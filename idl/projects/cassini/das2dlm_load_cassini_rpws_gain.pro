;+
; PRO: das2dlm_load_cassini_rpws_gain, ...
;
; Description: Calibrated Cassini data from Radio and Plasma Wave Science, das2 dataset: /Cassini/RPWS/...; 
;   Available datasets:
;     'LoFreq' - Wideband (WBR) or Waveform (WFR) calibrated reciever gain states
;     'MidHiFreq' - Wideband (WBR) or Waveform (WFR) calibrated reciever gain states
;            
; Keywords:
;    trange: Sets the time tange
;    source (optional): String that defines dataset (default: 'LoFreq')             
;    nset (optional): dataset number (default: 0)
;    resolution (optional): string of the resolution, (default, '')
;    parameter (optional): string of optional das2 parameters         
;   
; Note:
;   Please reffer to the das2.org catalog for additional information or examples of das2 use:
;   https://das2.org/browse/uiowa/cassini/rpws
;   
; CREATED BY:
;    Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2021-01-25 20:29:41 -0800 (Mon, 25 Jan 2021) $
; $Revision: 29621 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cassini/das2dlm_load_cassini_rpws_gain.pro $
;-

pro das2dlm_load_cassini_rpws_gain, trange=trange, nset=nset, source=source, resolution=resolution, parameter=parameter
  
  das2dlm_cassini_init
  
  if ~undefined(trange) && n_elements(trange) eq 2 $
   then tr = timerange(trange) $
   else tr = timerange()
   
   if undefined(nset) then nset = 0
   
   if undefined(source) $
     then source = 'LoFreq'
     
   if undefined(resolution) $
     then resolution = ''
     
   if resolution ne '' $
    then resolution = '&resolution=' + resolution
       
   if undefined(parameter) then parameter = ''      
   if parameter ne '' then parameter = '&params=' + parameter.Replace(' ','+')
  
  case strlowcase(source) of
    'lofreq': begin
      source = 'HiRes_LoFreq_Gain'
      t_name = 'time'
      v_arr = ['wfr_Ex_gain','wfr_Ew_gain','wfr_Bx_gain','wfr_By_gain','wfr_Bz_gain']
    end 
    'midhifreq': begin
      source = 'HiRes_MidHiFreq_Gain'
      t_name = 'time'
      v_arr = ['wbr_gain']      
    end
    else: begin
      dprint, dlevel = 0, 'Unknown source. Accepatable sources are: LoFreq or MidHiFreq'
      return
    end
  endcase
  
  time_format = 'YYYY-MM-DDThh:mm:ss'
  
  url = 'http://planet.physics.uiowa.edu/das/das2Server?server=dataset'
  dataset = 'dataset=Cassini/RPWS/' + source
  time1 = 'start_time=' + time_string( tr[0] , tformat=time_format)
  time2 = 'end_time=' + time_string( tr[1] , tformat=time_format)

  requestUrl = url + '&' + dataset + '&' + time1 + '&' + time2 + resolution + parameter
  print, requestUrl

  query = das2c_readhttp(requestUrl)
  
  ; Get dataset
  ds = das2c_datasets(query, nset)
  
  ; Get time
  das2dlm_get_ds_var, ds, 'time', 'center', p=pt, v=vt, m=mt, d=dt
  
  ; Exit on empty data
  if undefined(dt) then begin
    dprint, dlevel = 0, 'Dataset has no data for the selected period.'
    return
  endif
  
  ; Convert time
  dt = das2dlm_time_to_unixtime(dt, vt.units)
  
  ; Metadata
  das2dlm_get_ds_meta, ds, meta=mds, title=das2name

  str_element, DAS2, 'url', requestUrl, /add
  str_element, DAS2, 'name', das2name, /add ; ds.name does not contain usefull information in this case
  str_element, DAS2, 'propds', mds, /add ; ds.name does not contain usefull information in this case
  
  das2dlm_add_metadata, DAS2, p=pt, v=vt, m=mt, add='t' ; Time
  
  ; Get variables  
  for i=0,size(v_arr, /n_elem)-1 do begin
    name = v_arr[i]

    ; get variable
    das2dlm_get_ds_var, ds, name, 'center', p=py, v=vy, m=my, d=dy

    ; Copy DAS2 structure and modify
    DAS2_copy = DAS2
    das2dlm_add_metadata, DAS2, p=py, v=vy, m=my, add=''

    tvarname = 'cassini_ephemeris_' + source + '_' + name
    store_data, tvarname, data={x:dt, y:dy}
    options, /default, tvarname, 'colors', 0
    options, /default, tvarname, 'DAS2', DAS2 ; Store metadata (this should not affect graphics)
    options, /default, tvarname, 'title', name ; custom title

    ytitle = DAS2.name + ', ' + DAS2.units
    options, /default, tvarname, 'ytitle', ytitle ; Title from the properties
    
    ; Restore DAS2 structure
    DAS2 = DAS2_copy
  endfor
    
  ; Cleaning up
  res = das2c_free(query)  
end