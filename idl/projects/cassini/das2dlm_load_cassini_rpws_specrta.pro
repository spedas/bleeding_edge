;+
; PRO: das2dlm_load_cassini_rpws_spectra, ...
;
; Description: Cassini data from Radio and Plasma Wave Science, waveformw (PSD level 3 filed), das2 dataset: /Cassini/RPWS/...; 
;   Available datasets:
;     'HiRes_LoFreq_Spectra' - Collection: 25 Hz and 2.5 kHz, correlated 5-Component spectral densities (PDS level 3 files)
;     'HiRes MidFreq Spectra' - Collection: 10 kHz and 80 kHz Spectra from the WBR (PDS level 3 files)
;   Data may be retured from diffrent datasets. The tplot variables will indicate the dataset name (e.g. '_Ex_05') 
;            
; Keywords:
;    trange: Sets the time tange 
;    source (optional): String that defines dataset: 'MidFreq', 'LoFreq' (default: 'LoFreq')
;    output (optional): String (Case sensetive!), or array of strings of output data from this collection. 
;     One das2 request returns only one output, e.g. 'Bx' or 'By' or 'Bz' or 'Ew' or 'Ex'.
;     Collection HiRes_LoFreq_Spectra:
;       'Bx' - Waveform from the tri-axial search coil magnetic antenna Bx, detect magnetic components of electromagnetic waves
;       'By' - Waveform from the By antenna used as a monopole, detect magnetic components of electromagnetic waves
;       'Bz' - Waveform from the Bz antenna used as a monopole, detect magnetic components of electromagnetic waves
;       'Ew' - Waveform from the Ew electric monopole antenna
;       'Ex' - Waveform from the Eu and Ev electric dipole antennas, aligned along the x axis of the spacecraft
;       '7kHz' - Output spectra from 7.143 kHz rate waveforms, default is 100 Hz rate waveforms
;     Collection HiRes_MidFreq_Waveform (at this moment, onlye one parameter: Ew or Ex can be selected): 
;       'Ew' - Waveform from the Ew electric monopole antenna
;       'Ex' - Waveform from the Eu and Ev electric dipole antennas, aligned along the X axis of the spacecraft
;       '10khz' - band rolloff 10khz 
;       '80khz' - band rolloff to 80khz (default is 10khz)          
;     Examples:
;       output='Ex'
;       output=['Ew','80khz']          
;    resolution (optional): string of the resolution, e.g. '.21' (default, '')         
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
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cassini/das2dlm_load_cassini_rpws_specrta.pro $
;-

pro das2dlm_load_cassini_rpws_spectra, trange=trange, source=source, resolution=resolution, output=output, parameter=parameter
  
  das2dlm_cassini_init
  
  if ~undefined(trange) && n_elements(trange) eq 2 $
   then tr = timerange(trange) $
   else tr = timerange()
      
   if undefined(source) then source = 'LoFreq'
     
   if undefined(output) then output = ''   
     
   if undefined(parameter) then parameter = ''
     
   case strlowcase(source) of
    'lofreq': begin
      source = 'HiRes_LoFreq_Spectra'
      t_name = 'time'
      f_name = 'frequency'
      ; filter output and leave only acceptable parameters
      v_arr = strfilter(output,['Ex','Ew','Bx','By','Bz','7kHz'])
      ; We parameter is not empty, merge with the request
      if parameter ne '' then parameter = strjoin([v_arr, parameter], '+') $
      else parameter = strjoin(v_arr, '+')
      
      ; Remove '7khz' from v_arr, v_arr is a list of variables from now 
      if array_contains(v_arr, '7kHz') then v_arr = v_arr[where(v_arr ne '7kHz')]
      ; Check default (empty v_arrarr) 
      if not keyword_set(v_arr) then v_arr = ['Ex'] ; Default variable    
      
      ; NOTE: v_arr is not in use anymore, since we need to determine the variable name dynamically
                         
    end 
    'midfreq': begin
      source = 'HiRes_MidFreq_Spectra'
      t_name = 'time'
      f_name = 'frequency'
      v_arr = ['WBR'] 
      ; This collection uses diffrent way to process the parameters. Currently parameters Ew and Ex do not return data 
      output = strfilter(output,['Ex','Ew','10khz','80khz'])
      ; Set additional parameters
      aparam = []
      if array_contains(output, '10khz') then aparam = [aparam, '10khz']
      if array_contains(output, '80khz') then aparam = [aparam, '80khz']
      if array_contains(output, 'Ex') then aparam = [aparam, 'Ex']
      if array_contains(output, 'Ew') then aparam = [aparam, 'Ew']
            
      if parameter ne '' then parameter = strjoin([aparam, parameter], '+') $
      else if keyword_set(aparam) then parameter = strjoin(aparam, '+')  
      
      ; NOTE: v_arr is not in use anymore, since we need to determine the variable name dynamically    
    end
    else: begin
      dprint, dlevel = 0, 'Unknown source. Accepatable sources are: LoFreq or MidFreq'
      return
    end
   endcase
        
   if parameter ne '' then parameter = '&params=' + parameter.Replace(' ','+')
     
   if undefined(resolution) $
     then resolution = ''
     
   if resolution ne '' $
    then resolution = '&resolution=' + resolution
  
  time_format = 'YYYY-MM-DDThh:mm:ss'
  
  url = 'http://planet.physics.uiowa.edu/das/das2Server?server=dataset'
  dataset = 'dataset=Cassini/RPWS/' + source
  time1 = 'start_time=' + time_string( tr[0] , tformat=time_format)
  time2 = 'end_time=' + time_string( tr[1] , tformat=time_format)

  requestUrl = url + '&' + dataset + '&' + time1 + '&' + time2 + resolution + parameter
  print, requestUrl

  query = das2c_readhttp(requestUrl)
  
  if undefined(query) then begin
    dprint, dlevel = 0, 'Das2 returned invalid or empty query.'
    return
  endif
  
  ; Get dataset in case we have mulitple datasets
   for i=0,query.n_dsets-1 do begin
    nset = i
    ds = das2c_datasets(query, nset)  
    
    ; Get time
    das2dlm_get_ds_var, ds[0], t_name, 'center', p=pt, v=vt, m=mt, d=dt
  
    ; Exit on empty data
    ;if undefined(dt) then begin
    ;  dprint, dlevel = 0, 'Dataset has no data for the selected period.'
    ;  return
    ;endif
  
    ; Get frequency
    das2dlm_get_ds_var, ds[0], f_name, 'center', p=pf, v=vf, m=my, d=df
  
    ; We have to determine v_name dynamically, since it is not nessesary in the order of parameters
    das2dlm_get_ds_var_name, ds[0], vnames=vnames, exclude=[t_name, f_name]
    v_name = vnames[0]
    ; Get data variable
    das2dlm_get_ds_var, ds[0], v_name, 'center', p=pd, v=vd, m=md, d=dd
   
    ; Manually fix the dimentions according to variable's rank
    dt = transpose(dt[0, *],[1, 0])  
    df = df[*, 0]
    dd = transpose(dd, [1, 0])
    
    ; Convert time
    dt = das2dlm_time_to_unixtime(dt, vt.units)

    tvarname = 'cassini_rpws_' + strlowcase(source)  + '_' + ds[0].name ; + v_name ; ds[0].name also contains the dataset number  
    store_data, tvarname, data={x:dt, y:dd, v:df}, $
      dlimits={spec:1, ylog:1, zlog:1} 
          
    ; Metadata
    das2dlm_get_ds_meta, ds[0], meta=mds, title=das2name
    
    str_element, DAS2, 'url', requestUrl, /add
    str_element, DAS2, 'name', das2name, /add
    str_element, DAS2, 'propds', mds, /add ; add data set property
  
    das2dlm_add_metadata, DAS2, p=pt, v=vt, m=mt, add='x'
    das2dlm_add_metadata, DAS2, p=pd, v=vd, m=md, add='y' 
    das2dlm_add_metadata, DAS2, p=pf, v=vf, m=mf, add='v' 
    
    options, /default, tvarname, 'DAS2', DAS2 ; Store metadata (this should not affect graphics)
    
    options, /default, tvarname, 'title', DAS2.name
    ; Data Label
    ytitle = DAS2.namey + ', ' + DAS2.unitsy
    options, /default, tvarname, 'ytitle', ytitle ;
    
    ; Clear ds (some strange crashes happen if this is not included'
    ds = !null    
  endfor
  
  ; Cleaning up
  res = das2c_free(query)  
end