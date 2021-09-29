;+
; PRO: das2dlm_load_cassini_mag_dc11, ...
;
; Description:
;    Loads Difference between the C11 model field and Cassini MAG 1-second observations using das2dlm library
;    dataset: Cassini/MAG/Differential_C11
;
; Keywords:
;    trange: Sets the time tange
;    parameter (optional): string of optional das2 parameters  
;    
; Note:
;   Please reffer to the das2.org catalog for additional information or examples of das2 use:
;   https://das2.org/browse/uiowa/cassini/mag    
;    
; CREATED BY:
;    Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2021-01-25 20:29:41 -0800 (Mon, 25 Jan 2021) $
; $Revision: 29621 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cassini/das2dlm_load_cassini_mag_dc11.pro $
;-

pro das2dlm_load_cassini_mag_dc11, trange=trange, parameter=parameter
  
  das2dlm_cassini_init
  
  t_name = 'time'
  x_name = 'radial'
  y_name = 'southward'
  z_name = 'azimuthal'
      
  if ~undefined(trange) && n_elements(trange) eq 2 $
   then tr = timerange(trange) $
   else tr = timerange()
       
   if undefined(parameter) then parameter = ''
   if parameter ne '' then parameter = '&params=' + parameter.Replace(' ','+')
  
  time_format = 'YYYY-MM-DDThh:mm:ss'
  
  url = 'http://planet.physics.uiowa.edu/das/das2Server?server=dataset'
  dataset = 'dataset=Cassini/MAG/Differential_C11'
  time1 = 'start_time=' + time_string( tr[0] , tformat=time_format)
  time2 = 'end_time=' + time_string( tr[1] , tformat=time_format)

  requestUrl = url + '&' + dataset + '&' + time1 + '&' + time2
  print, requestUrl

  query = das2c_readhttp(requestUrl)
  
  ; Get dataset
  ds = das2c_datasets(query, 0)
  
  ; Get time
  das2dlm_get_ds_var, ds, t_name, 'center', p=pt, v=vt, m=mt, d=dt
  
  ; Exit on empty data
  if undefined(dt) then begin
    dprint, dlevel = 0, 'Dataset has no data for the selected period.'
    return
  endif
  
 ; Convert time
  dt = das2dlm_time_to_unixtime(dt, vt.units)
  
  ; get Var
  das2dlm_get_ds_var, ds, x_name, 'center', p=px, v=vx, m=mx, d=dx
  das2dlm_get_ds_var, ds, y_name, 'center', p=py, v=vy, m=my, d=dy
  das2dlm_get_ds_var, ds, z_name, 'center', p=pz, v=vz, m=mz, d=dz
    
  ; Metadata
  das2dlm_get_ds_meta, ds, meta=mds, title=das2name
       
  str_element, DAS2, 'url', requestUrl, /add
  str_element, DAS2, 'name', das2name, /add ; use property of dataset
  str_element, DAS2, 'propds', mds, /add ; add data set property

  das2dlm_add_metadata, DAS2, p=pt, v=vt, m=mt, add='t'
  das2dlm_add_metadata, DAS2, p=px, v=vx, m=mx, add='x'
  das2dlm_add_metadata, DAS2, p=py, v=vy, m=my, add='y'
  das2dlm_add_metadata, DAS2, p=pz, v=vz, m=mz, add='z'  
    
  tvarname = 'cassini_mag_dc11'
  store_data, tvarname, data={x:dt, y:[[dx], [dy], [dz]]}
  options, /default, tvarname, 'colors', ['r', 'g', 'b'] ; multiple colors 
  options, /default, tvarname, 'DAS2', DAS2 ; Store metadata (this should not affect graphics)
  options, /default, tvarname, 'title', DAS2.name ; custom title
  
  ytitle = 'dB (C11)' + ', ' + DAS2.unitsx ; Custom name
  options, /default, tvarname, 'ytitle', ytitle ; Title from the properties

end