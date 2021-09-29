;+
;NAME:
;   icon_crib_mighti
;
;PURPOSE:
;   Example of loading and plotting ICON data for the MIGHTI instrument
;
;KEYWORDS:
;   step: (optional) selects the example to run, if 99 then it runs all of them
;   img_path: (optional) Directory where the plot files will be saved
;
;KEYWORDS:
;
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2020-01-28 17:58:46 -0800 (Tue, 28 Jan 2020) $
;$LastChangedRevision: 28246 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/examples/icon_crib_mighti.pro $
;
;-------------------------------------------------------------------

pro icon_crib_mighti, step=step, img_path=img_path

  ; TODO:Data can be downloaded only locally for now
  localdirsim = '/disks/data/icon/Repository/Archive/Simulated-Data/'
  result = FILE_TEST(localdirsim, /directory, /read)
  if not result then begin
    print, "For now, ICON data can only be downloaded inside SSL."
    return
  endif
  
  ; Specify a time range
  timeRange = ['2010-05-21/22:58:00', '2010-05-22/01:02:00']
  ; Specify a directory for images
  if ~keyword_set(img_path) then begin
    if (!D.NAME eq 'WIN') then img_path = 'C:\temp\icon\' else img_path = 'temp/icon/'
  endif

  if ~keyword_set(step) then step = 1

  cdf_leap_second_init

  if step eq 1 or step eq 99 then begin
    ;MIGHTI-A Level-1
    del_data, '*'
    instrument = 'mighti'
    datal1type = '*'
    datal2type = ''
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type

    tplot_options, 'title', 'ICON MIGHTI-A'

    ylim, 'ICON_L0_MIGHTI_A_Optics_Temperature_Aft', 24500D, 24800D, style=0
    options, 'ICON_L0_MIGHTI_A_Optics_Temperature_Aft', 'psym', 4
    options, 'ICON_L0_MIGHTI_A_Optics_Temperature_Aft', 'ytitle', 'Temperature'

    tplot, ['ICON_L0_MIGHTI_A_Optics_Temperature_Aft']    

    ;makepng,img_path + 'ICON_MIGHTI_A_L1_Example'
    
    ; The following variables depend of altitudes 
    get_data, 'ICON_L1_MIGHTI_A_Green_Relative_Brightness', data=d, dl=dl
    ;store_data, 'ICON_L1_MIGHTI_A_Green_Relative_Brightness2', data={x:d.x, y:d.y, v1:transpose(d.v1), v2:transpose(d.v2), dl:dl} 
    store_data, 'ICON_L1_MIGHTI_A_Green_Relative_Brightness2', data={x:d.x, y:d.y}
    options, 'ICON_L1_MIGHTI_A_Green_Relative_Brightness2', 'ytitle', 'Green Relative!CBrightness'
 
    get_data, 'ICON_L1_MIGHTI_A_Red_Relative_Brightness', data=d2, dl=dl2
    ;store_data, 'ICON_L1_MIGHTI_A_Red_Relative_Brightness2', data={x:d.x, y:d2.y, v1:transpose(d2.v1), v2:transpose(d2.v2), dl:dl2}
    store_data, 'ICON_L1_MIGHTI_A_Red_Relative_Brightness2', data={x:d.x, y:d2.y}
    options, 'ICON_L1_MIGHTI_A_Red_Relative_Brightness2', 'ytitle', 'Red Relative!CBrightness' 
    
    get_data, 'ICON_L1_MIGHTI_A_Red_Array_Altitudes', data=d3, dl=dl3
    store_data, 'ICON_L1_MIGHTI_A_Red_Array_Altitudes2', data={x:d.x, y:transpose(d3.y)}        
    options, 'ICON_L1_MIGHTI_A_Red_Array_Altitudes2', 'ytitle', 'Red Altitudes'
    
    tplot, ['ICON_L0_MIGHTI_A_Optics_Temperature_Aft', 'ICON_L1_MIGHTI_A_Green_Relative_Brightness2', $
      'ICON_L1_MIGHTI_A_Red_Relative_Brightness2','ICON_L1_MIGHTI_A_Red_Array_Altitudes2']
      
    ;Time series:
    ;ICON_L0_MIGHTI_A_OPTICS_TEMPERATURE_AFT

    ;Spectrogram:
    ;ICON_L1_MIGHTI_A_GREEN_ARRAY_RELATIVE_BRIGHTNESS
    ;ICON_L1_MIGHTI_A_RED_ARRAY_RELATIVE_BRIGHTNESS
    ;ICON_L1_MIGHTI_A_RED_ARRAY_ALTITUDES

  endif
  
  if step eq 2 or step eq 99 then begin
    ;MIGHTI Level-2 Wind
    del_data, '*'
    
    timeRange = ['2010-05-21/00:00:00', '2010-05-21/23:59:59']
    instrument = 'mighti'
    datal1type = ''
    datal2type = '*'
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type    
    
    options, 'ICON_L2_MIGHTI_RED_ZONAL_WIND', 'ytitle', 'Red Zonal'    
    options, 'ICON_L2_MIGHTI_RED_MERIDIONAL_WIND', 'ytitle', 'Red Meridional'    
    options, 'ICON_L2_MIGHTI_GREEN_ZONAL_WIND', 'ytitle', 'Green Zonal'    
    options, 'ICON_L2_MIGHTI_GREEN_MERIDIONAL_WIND', 'ytitle', 'Green Meridional'    

    tplot_options, 'title', 'ICON MIGHTI Wind (Level-2 Data)'

    ;makepng,img_path + 'ICON_MIGHTI_L2_Example'
    
    tplot, ['ICON_L2_MIGHTI_RED_ZONAL_WIND', 'ICON_L2_MIGHTI_RED_MERIDIONAL_WIND','ICON_L2_MIGHTI_GREEN_ZONAL_WIND',$
      'ICON_L2_MIGHTI_GREEN_MERIDIONAL_WIND']

    ;Spectrogram:
    ;ICON_L2_MIGHTI_RED_ZONAL_WIND
    ;ICON_L2_MIGHTI_RED_MERIDIONAL_WIND
    ;ICON_L2_MIGHTI_GREEN_ZONAL_WIND
    ;ICON_L2_MIGHTI_GREEN_MERIDIONAL_WIND

  endif  

  if step eq 3 or step eq 99 then begin
    ;MIGHTI Level-2 Temperature
    del_data, '*'

    timeRange = ['2010-05-21/00:00:00', '2010-05-21/23:59:59']
    instrument = 'mighti'
    datal1type = ''
    datal2type = '*'
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type


    get_data, 'ICON_L2_MIGHTI_A_Temperatures', data=d, dlimits=dlimits
    store_data, 'ICON_L2_MIGHTI_A_Temperatures0', data={x:d.x, y:d.y, v:d.v[*, 0]}, dlimits=dlimits

    get_data, 'ICON_L2_MIGHTI_A_Temp_Total_Uncertainties', data=d, dlimits=dlimits
    store_data, 'ICON_L2_MIGHTI_A_Temp_Total_Uncertainties0', data={x:d.x, y:d.y, v:d.v[*, 0]}, dlimits=dlimits


    options, 'ICON_L2_MIGHTI_A_Boresight_Sun_Angle', 'ytitle', 'Boresight!CSun Angle'
    options, 'ICON_L2_Ancillary_SC_LST', 'ytitle', 'Ancillary SC LST'
    options, 'ICON_L2_MIGHTI_A_Temperatures0', 'ytitle', 'Temperatures'
    options, 'ICON_L2_MIGHTI_A_Temp_Total_Uncertainties0', 'ytitle', 'Total Uncertainties'
    
    tplot_options, 'title', 'ICON MIGHTI Temperature (Level-2 Data)'
 
    ;makepng, img_path + 'ICON_MIGHTI_L2_Temp_Example'

    tplot, ['ICON_L2_MIGHTI_A_Boresight_Sun_Angle','ICON_L2_Ancillary_SC_LST', 'ICON_L2_MIGHTI_A_Temperatures0', 'ICON_L2_MIGHTI_A_Temp_Total_Uncertainties0' ]

    ;Line plot:
    ;ICON_L2_MIGHTI_A_Boresight_Sun_Angle
    ;ICON_L2_Ancillary_SC_LST
    ;
    ;Spectrogram:
    ;ICON_L2_MIGHTI_A_Temperatures0
    ;ICON_L2_MIGHTI_A_Temp_Total_Uncertainties0 

  endif
  
  if step eq 4 or step eq 99 then begin
    ;MIGHTI-A Level-2 Temperature
    del_data, '*'

    timeRange = ['2010-05-27/00:00:00', '2010-05-27/23:59:59']
    instrument = 'mighti-a'
    datal1type = ''
    datal2type = '*'
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    tplot_options, 'title', 'ICON MIGHTI-A Temperature (Level-2 Data)'
    
    ;makepng, img_path + 'ICON_MIGHTI_L2_Temp_Example'

    tplot, ['ICON_L2_MIGHTI_A_Temperatures','ICON_L2_MIGHTI_A_Tangent_LST']

  endif
  
  
  if step eq 5 or step eq 99 then begin
    ;MIGHTI-B Level-2 Temperature
    del_data, '*'

    timeRange = ['2010-05-27/00:00:00', '2010-05-27/23:59:59']
    instrument = 'mighti-b'
    datal1type = ''
    datal2type = '*'
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    tplot_options, 'title', 'ICON MIGHTI-B Temperature (Level-2 Data)'

    ;makepng, img_path + 'ICON_MIGHTI_L2_Temp_Example'

    tplot, ['ICON_L2_MIGHTI_B_Temperatures','ICON_L2_MIGHTI_B_Tangent_LST']

  endif
  print, 'icon_crib_mighti finished'
end