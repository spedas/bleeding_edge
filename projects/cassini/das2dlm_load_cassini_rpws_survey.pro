;+
; PRO: das2dlm_load_cassini_rpws_survey, ...
;
; Description: Calibrated Cassini data from Radio and Plasma Wave Science, das2 dataset: /Cassini/RPWS/...; 
;   Available datasets:
;     'Survey' - Calibrated, full-resolution, low-rate electric survey data (PDS level 3 files)
;     'Survey_Grid' - Calibrated, gridded, low-rate survey data (CODMAC Level 4)
;     'Survey_KeyParam' - Calibrated, reduced resolution, low-rate survey data (CODMAC level 4)
;     'Survey_Magnetic' - Calibrated, full-resolution, low-rate magnetic survey data (PDS level 3 files)
;   There are several datasets that can be selected (controlled by nset):
;     'Survey' and 'Survey_Magnetic' - 0 to 5 datasets
;     'Survey_KeyParam' and 'Survey_Magnetic' - dataset number 0    
;            
; Keywords:
;    trange: Sets the time tange
;    source (optional): String that defines dataset (default: 'Survey')             
;    nset (optional): dataset number (default: 0)
;    resolution (optional): string of the resolution, e.g. '43.2' (default, '')
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
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cassini/das2dlm_load_cassini_rpws_survey.pro $
;-

pro das2dlm_load_cassini_rpws_survey, trange=trange, nset=nset, source=source, resolution=resolution, parameter=parameter
  
  das2dlm_cassini_init
  
  if ~undefined(trange) && n_elements(trange) eq 2 $
   then tr = timerange(trange) $
   else tr = timerange()
   
   if undefined(nset) then nset = 0
   
   if undefined(source) $
     then source = 'Survey'
     
   if undefined(resolution) $
     then resolution = ''
     
   if resolution ne '' $
    then resolution = '&resolution=' + resolution
       
   if undefined(parameter) then parameter = ''      
   if parameter ne '' then parameter = '&params=' + parameter.Replace(' ','+')
  
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
  
  ; Get frequency
  das2dlm_get_ds_var, ds, 'frequency', 'center', p=pf, v=vf, m=mf, d=df
  
  ; Get amplitude or electric_specdens
  ; find the variable
  ; We have to obtain the variables in the loop since we don't know the name
  pdims = das2c_pdims(ds) ; get all pdims
  nd = size(pdims, /n_elem)
  
  ; Get variable name
  das2dlm_get_ds_var_name, ds[0], vnames=vnames, exclude=['time', 'frequency']
  name = vnames[0]
  
  ; Old method of getting the variable name
  ;name = ''  
  ;for i=0,nd-1 do begin
  ;  name = pdims[i].pdim
  ;  if strcmp(name, 'time',/fold) then continue
  ;  if strcmp(name, 'frequency',/fold) then continue
  ;endfor
  
  ; we must have variable name after that
  if name eq '' then begin
    dprint, dlevel = 0, 'Error: Valid variable name not found'
    return    
  endif 
  
  das2dlm_get_ds_var, ds, name, 'center', p=pa, v=va, m=ma, d=da
  
  ; Convert time
  dt = das2dlm_time_to_unixtime(dt, vt.units)
  
  ; Manually fix the dimentions according to variable's rank  
  dt = transpose(dt[0, *],[1, 0])  
  df = df[*, 0]
  da = transpose(da, [1, 0])
 
  tvarname = 'cassini_rpws_' + strlowcase(source)  + '_' + ds[0].name
  store_data, tvarname, data={x:dt, y:da, v:df}, $
    dlimits={spec:1, ylog:1, zlog:1} ;, ytitle:props_freq[0].value, ztitle:props_spec[0].value}
  ;options, /default, tvarname, 'colors', 0
    
  ; Metadata
  das2dlm_get_ds_meta, ds[0], meta=mds, title=das2name
    
  str_element, DAS2, 'url', requestUrl, /add
  str_element, DAS2, 'name', das2name, /add
  str_element, DAS2, 'propds', mds, /add ; add data set property

  str_element, DAS2, 'namex', pt.pdim, /add
  str_element, DAS2, 'namey', pa.pdim, /add
  str_element, DAS2, 'namev', pf.pdim, /add

  str_element, DAS2, 'usex', pt.use, /add
  str_element, DAS2, 'usey', pa.use, /add
  str_element, DAS2, 'usev', pf.use, /add

  str_element, DAS2, 'unitsx', vt.units, /add
  str_element, DAS2, 'unitsy', va.units, /add
  str_element, DAS2, 'unitsv', vf.units, /add

  str_element, DAS2, 'propsx', mt, /add
  str_element, DAS2, 'propsy', ma, /add 
  str_element, DAS2, 'propsv', mf, /add
  
  options, /default, tvarname, 'DAS2', DAS2 ; Store metadata (this should not affect graphics)
  
  options, /default, tvarname, 'title', tvarname
  ; Data Label
  ytitle = DAS2.namev + ', ' + DAS2.unitsv
  ztitle = DAS2.namey + ', ' + DAS2.unitsy
  options, /default, tvarname, 'ytitle', ytitle ;
  options, /default, tvarname, 'ztitle', ztitle ;
  
  ; Cleaning up
  res = das2c_free(query)  
end