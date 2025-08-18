;+
; PRO: das2dlm_load_cassini_mag_vec, ...
;
; Description:
;    Loads Cassini Magnetometer Vector values data using das2dlm library
;    dataset: Cassini/MAG/<dataset>
;
; Keywords:
;    trange: Sets the time tange
;    source (optional): String that defines dataset: 
;     'VectorSC' (default) - Magnetometer Data in Spacecraft Coordinates from http://mapsview.engin.umich.edu/;
;     'VectorKSO' - Magnetometer Vector values in Kronocentric Solar Orbital coordinates from PDS volume CO-E_SW_J_S-MAG-4-SUMM-1SECAVG-V1.0
;    coord (optional): If source = 'VectirKSO' additional parameters can be specified:
;     'J3' - Jovicentric Body-Fixed IAU_JUPITER
;     'Jmxyz' - Jovicentric Body-Fixed Magnetospheric Coordinates
;     'Krtp' - Output in Kronocentric body-fixed, J2000 spherical Coordinates
;     'Ksm' - Kronocentric Solar Magnetospheric Coordinates
;     'Kso' - default Output vectors in Kronocentric Solar Orbital Coordinates
;     'Rtn' - Output in Radial-Tangential-Normal coordinates          
;    resolution (optional): string of the resolution, e.g. '43.2' (default, '')
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
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cassini/das2dlm_load_cassini_mag_vec.pro $
;-

pro das2dlm_load_cassini_mag_vec, trange=trange, source=source, parameter=parameter, coord=coord, resolution=resolution
  
  das2dlm_cassini_init
  
  if undefined(source) $
  then source = 'VectorSC'  
 
  if undefined(coord) then coord = '' ; by default it is empty string
  case strlowcase(source) of
   'vectorsc': begin
       t_name = 'time'
       x_name = 'x'
       y_name = 'y'
       z_name = 'z'
       b_name = 'total'
       tplot_name = source
     end 
   'vectorkso': begin
     t_name = 'time'
     x_name = 'X'
     y_name = 'Y'
     z_name = 'Z'
     b_name = 'magnitude'
     tplot_name = source    
         
     case strupcase(coord) of
      'KRTP' : begin
        x_name = 'radial'
        y_name = 'southward'
        z_name = 'azimuthal'
        end
      'RTN' : begin
        x_name = 'radial'
        y_name = 'tangental'
        z_name = 'normal'
        end
      else: begin
        end
     endcase
     tplot_name += '_' + strupcase(coord)
    end
  else: begin
        dprint, dlevel = 0, 'Unknown source. Accepatable sources are: VectorSC or VectorKSC'
        return    
        end    
  endcase
  
  if undefined(parameter) then parameter = ''

  if (coord ne '' and parameter ne '') then parameter = coord + ' ' + parameter $
  else if coord ne '' then parameter = coord

  if parameter ne '' then parameter = '&params=' + parameter.Replace(' ','+') 
      
  if undefined(resolution) $
   then resolution = ''

  if resolution ne '' $
   then resolution = '&resolution=' + resolution
      
  if ~undefined(trange) && n_elements(trange) eq 2 $
   then tr = timerange(trange) $
   else tr = timerange()
  
  time_format = 'YYYY-MM-DDThh:mm:ss'  
  url = 'http://planet.physics.uiowa.edu/das/das2Server?server=dataset'
  dataset = 'dataset=Cassini/MAG/' + source
  time1 = 'start_time=' + time_string( tr[0] , tformat=time_format)
  time2 = 'end_time=' + time_string( tr[1] , tformat=time_format)

  requestUrl = url + '&' + dataset + '&' + time1 + '&' + time2 + parameter + resolution
  print, requestUrl

  query = das2c_readhttp(requestUrl)
  
  ; Get dataset
  ds = das2c_datasets(query)
  
  ; Get variables
  das2dlm_get_ds_var, ds, t_name, 'center', p=pt, v=vt, m=mt, d=dt  
  das2dlm_get_ds_var, ds, x_name, 'center', p=px, v=vx, m=mx, d=dx
  das2dlm_get_ds_var, ds, y_name, 'center', p=py, v=vy, m=my, d=dy
  das2dlm_get_ds_var, ds, z_name, 'center', p=pz, v=vz, m=mz, d=dz
  das2dlm_get_ds_var, ds, b_name, 'center', p=pb, v=vb, m=mb, d=db
    
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
  str_element, DAS2, 'name', das2name, /add
  str_element, DAS2, 'propds', mds, /add ; add data set property
  
  das2dlm_add_metadata, DAS2, p=pt, v=vt, m=mt, add='t'
  das2dlm_add_metadata, DAS2, p=px, v=vx, m=mx, add='x'
  das2dlm_add_metadata, DAS2, p=py, v=vy, m=my, add='y'
  das2dlm_add_metadata, DAS2, p=pz, v=vz, m=mz, add='z'
  
  ; Components variable 
  tvarname = 'cassini_mag_' + tplot_name
  store_data, tvarname, data={x:dt, y:[[dx], [dy], [dz]]}
  options, /default, tvarname, 'colors', ['r', 'g', 'b'] ; multiple colors  
  options, /default, tvarname, 'DAS2', DAS2 ; Store metadata (this should not affect graphics)  
  ;options, /default, tvarname, 'title', 'Magnetometer Vector' ; custom title
  options, /default, tvarname, 'title', DAS2.name ; custom title
  
  ; Data Label
  ytitle = tplot_name + ', ' + DAS2.unitsx
  ; str_element, my[0], 'key', success=s
  ; if s eq 1 then str_element, my[0], 'value', ytitle    
  options, /default, tvarname, 'ytitle', ytitle ; Title from the properties
  
  ; Total variable 
  tvarname = 'cassini_mag_' + tplot_name + '_' + b_name
  store_data, tvarname, data={x:dt, y:db}
  options, /default, tvarname, 'colors', 0
  DAS2 = [] 
  ; Metadata
  str_element, DAS2, 'url', requestUrl, /add
  str_element, DAS2, 'name', source, /add ; ds.name does not contain usefull information in this case

  das2dlm_add_metadata, DAS2, p=pt, v=vt, m=mt, add='t'
  das2dlm_add_metadata, DAS2, p=pb, v=vb, m=mb, add='y'
      
  options, /default, tvarname, 'DAS2', DAS2 ; Store metadata (this should not affect graphics)
  options, /default, tvarname, 'title', DAS2.name ; custom title
  ytitle = DAS2.name + ' ' + DAS2.namey + ', ' + DAS2.unitsy
  options, /default, tvarname, 'ytitle', ytitle ; Title from the properties
  
  ; Cleaning up
  res = das2c_free(query)
end