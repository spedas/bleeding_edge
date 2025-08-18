;+
;NAME:
;   icon_crib
;
;PURPOSE:
;   Examples of loading and plotting ICON data
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
;$LastChangedDate: 2020-02-19 11:51:19 -0800 (Wed, 19 Feb 2020) $
;$LastChangedRevision: 28318 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/examples/icon_crib.pro $
;
;-------------------------------------------------------------------

pro icon_crib, step=step, img_path=img_path

  ; TODO: Data can be downloaded only inside SSL, for now
  ; The user must have access to SSL icon simulated data
  
  icon_init
  simulated_data_path = '/disks/data/icon/Repository/Archive/Simulated-Data/'
  result = FILE_TEST(simulated_data_path, /directory, /read)
  if not result then begin
    print, "For now, ICON data can only be downloaded inside SSL."
    return
  endif
  !icon.REMOTE_DATA_DIR = simulated_data_path
   
  ; We need to set the local directory for saving images 
  if ~keyword_set(img_path) then begin
    if (!D.NAME eq 'WIN') then img_path = 'C:\\temp\\icon\\' else img_path = '~/temp/icon/'
  endif
  result = FILE_TEST(img_path, /directory, /read)
  save_image = 1
  if not result then begin
    save_image = 0
  endif 

  ; Specify a time range
  trange = ['2010-05-23/00:00', '2010-05-24/23:59:59']

  ; Start examples
  if ~keyword_set(step) then step = 1

  ; Initiallize tt2000 times
  cdf_leap_second_init

  if step eq 1 or step eq 99 then begin
    ; L1 FUV LWP
    del_data, '*'
    ; Specify an instrument
    instrument = 'fuv'
    ; Specify a data type to load
    datal1type = 'lwp'
    datal2type = ''
    ; Load ICON data
    icon_load_data, trange = trange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    ; Print the names of loaded tplot variables
    tplot_names

    ; Specify plot options
    options, 'ICON_L1_FUVB_LWP_HV_PHOS', 'yrange', [45.6, 46.2]
    options, 'ICON_L1_FUVB_LWP_HV_PHOS', 'ytitle', 'HV PHOS !C'
    options, 'ICON_L1_FUVB_LWP_HV_PHOS', 'psym', 3

    options, 'ICON_L1_FUVB_Board_TEMP', 'yrange', [27.2, 28.0]
    options, 'ICON_L1_FUVB_Board_TEMP', 'ytitle', 'Board TEMP !C'
    options, 'ICON_L1_FUVB_Board_TEMP', 'psym', 3

    options, 'ICON_L1_FUVB_LWP_Raw_P0', 'ytitle', 'Raw P0 !C'

    options, 'ICON_L1_FUVB_LWP_PROF_P0_Error', 'ytitle', 'PROF P0 Error !C'

    ylim, 'ICON_L1_FUVB_LWP_Raw*', 0, 255
    ylim, 'ICON_L1_FUVB_LWP_PROF*', 0, 255

    ; Fill gaps with NaN
    tdegap, ['ICON_L1_FUVB_LWP_Raw_P0','ICON_L1_FUVB_LWP_PROF_P0_Error'], overwrite=1, /twonanpergap

    ; Title for the plot
    tplot_options, 'title', 'ICON FUV L1 LWP'

    ; Plot data
    tplot, ['ICON_L1_FUVB_LWP_HV_PHOS', 'ICON_L1_FUVB_Board_TEMP','ICON_L1_FUVB_LWP_Raw_P0','ICON_L1_FUVB_LWP_PROF_P0_Error']
    ; Save png file
    if save_image then makepng, img_path + '1_ICON_FUV_L1_LWP'
    ; Print time limits
    get_data,'ICON_L1_FUVB_LWP_HV_PHOS',data=d, dlimits = dl
    print, 'Times: ', time_string(d.x[0]), ' to ' , time_string(d.x[n_elements(d.x)-1])
    
  endif

  if step eq 2 or step eq 99 then begin
    ; L1 FUV SWP
    del_data, '*'
    instrument = 'fuv'
    datal1type = 'swp'
    datal2type = ''
    icon_load_data, trange = trange, instrument = instrument, datal1type = datal1type, datal2type = datal2type

    options, 'ICON_L1_FUVA_SWP_HV_MCP', 'yrange', [19.4, 19.7]
    options, 'ICON_L1_FUVA_CCD_TEMP', 'yrange', [18.0,20.0]

    options, 'ICON_L1_FUVA_SWP_HV_MCP', 'ytitle', 'HV MCP !C'
    options, 'ICON_L1_FUVA_CCD_TEMP', 'ytitle', 'CCD TEMP !C'
    options, 'ICON_L1_FUVA_SWP_Raw_M3', 'ytitle', 'SWP Raw M3 !C'
    options, 'ICON_L1_FUVA_SWP_PROF_M3_Error', 'ytitle', 'PROF M3 Error !C'

    options, 'ICON_L1_FUVA_SWP_HV_MCP', 'psym', 3
    options, 'ICON_L1_FUVA_CCD_TEMP', 'psym', 3

    ylim, 'ICON_L1_FUVA_SWP_Raw*', 0, 255
    ylim, 'ICON_L1_FUVA_SWP_PROF*', 0, 255

    tplot_options, 'title', 'ICON FUV L1 SWP'
    tdegap, ['ICON_L1_FUVA_SWP_Raw_M3','ICON_L1_FUVA_SWP_PROF_M3_Error'], overwrite=1, /twonanpergap
    tplot, ['ICON_L1_FUVA_SWP_HV_MCP', 'ICON_L1_FUVA_CCD_TEMP','ICON_L1_FUVA_SWP_Raw_M3','ICON_L1_FUVA_SWP_PROF_M3_Error']

    if save_image then makepng, img_path + '2_ICON_FUV_L1_SWP'
  endif

  if step eq 3 or step eq 99 then begin
    ; L1 FUV SLI
    del_data, '*'
    instrument = 'fuv'
    datal1type = 'sli'
    datal2type = ''
    icon_load_data, trange = trange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    tplot_names

    get_data, 'ICON_L1_FUVA_Limb_Raw', data=d, dlimits=dlimits
    store_data, 'ICON_L1_FUVA_Limb_Raw1', data={x:d.x, y:reform(d.y[*,52,*]), v:d.v1}, dlimits=dlimits
    ylim, 'ICON_L1_FUVA_Limb_Raw1', 80,210

    get_data, 'ICON_L1_FUVA_Limb_IMG', data=d, dlimits=dlimits
    store_data, 'ICON_L1_FUVA_Limb_IMG1', data={x:d.x, y:reform(d.y[*,52,*]), v:d.v1}, dlimits=dlimits
    ylim, 'ICON_L1_FUVA_Limb_IMG1', 80,210
    zlim, 'ICON_L1_FUVA_Limb_IMG1', 0, 2

    options, 'ICON_L1_FUVA_SWI_Chain_ID', 'psym', 3
    options, 'ICON_L1_FUV_OPT_TEMP', 'psym', 3

    options, 'ICON_L1_FUVA_SWI_Chain_ID', 'ytitle', 'SWI Chain ID !C'
    options, 'ICON_L1_FUV_OPT_TEMP', 'ytitle', 'OPT TEMP !C'
    options, 'ICON_L1_FUVA_Limb_Raw1', 'ytitle', 'Limb Raw 52 !C'
    options, 'ICON_L1_FUVA_Limb_IMG1', 'ytitle', 'Limb IMG 52 !C'

    tplot_options, 'title', 'ICON FUV L1 SLI'
    tdegap, ['ICON_L1_FUVA_Limb_Raw1','ICON_L1_FUVA_Limb_IMG1'], overwrite=1, /twonanpergap
    tplot, ['ICON_L1_FUVA_SWI_Chain_ID', 'ICON_L1_FUV_OPT_TEMP','ICON_L1_FUVA_Limb_Raw1','ICON_L1_FUVA_Limb_IMG1']
    if save_image then makepng, img_path + '3_ICON_FUV_L1_SLI'
    ;Spectrograms: ICON_L1_FUVA_LIMB_RAW[*,52,*] and ICON_L1_FUVA_LIMB_IMG[*,52,*]
  endif

  if step eq 4 or step eq 99 then begin
    ; L1 FUV SSI
    del_data, '*'
    instrument = 'fuv'
    datal1type = 'ssi'
    datal2type = ''
    icon_load_data, trange = trange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    tplot_names

    get_data, 'ICON_L1_FUVA_Sublimb_Raw', data=d, dlimits=dlimits
    store_data, 'ICON_L1_FUVA_Sublimb_Raw1', data={x:d.x, y:reform(d.y[*,60,*]), v:d.v1}, dlimits=dlimits
    ylim, 'ICON_L1_FUVA_Sublimb_Raw1', 0, 255
    zlim, 'ICON_L1_FUVA_Sublimb_Raw1', 0., 2.e5

    get_data, 'ICON_L1_FUVA_Sublimb_IMG', data=d, dlimits=dlimits
    store_data, 'ICON_L1_FUVA_Sublimb_IMG1', data={x:d.x, y:reform(d.y[*,60,*]), v:d.v1}, dlimits=dlimits
    ylim, 'ICON_L1_FUVA_Sublimb_IMG1', 0, 255
    zlim, 'ICON_L1_FUVA_Sublimb_IMG1', 0., 1.

    options, 'ICON_L1_FUVA_SWI_Integration_Time', 'yrange', [11.0, 14.0]

    options, 'ICON_L1_FUVA_SWI_Integration_Time', 'psym', 3
    options, 'ICON_L1_FUV_IMG_TEMP', 'psym', 3

    options, 'ICON_L1_FUVA_SWI_Integration_Time', 'ytitle', 'SWI Integration Time !C'
    options, 'ICON_L1_FUV_IMG_TEMP', 'ytitle', 'IMG TEMP !C'
    options, 'ICON_L1_FUVA_Sublimb_Raw1', 'ytitle', 'Sublimb Raw 60 !C'
    options, 'ICON_L1_FUVA_Sublimb_IMG1', 'ytitle', 'Sublimb IMG 60 !C'

    tplot_options, 'title', 'ICON FUV L1 SSI'
    tdegap, ['ICON_L1_FUVA_Sublimb_Raw1','ICON_L1_FUVA_Sublimb_IMG1'], overwrite=1, /twonanpergap
    tplot, ['ICON_L1_FUVA_SWI_Integration_Time', 'ICON_L1_FUV_IMG_TEMP','ICON_L1_FUVA_Sublimb_Raw1','ICON_L1_FUVA_Sublimb_IMG1']
    if save_image then makepng,img_path + '4_ICON_FUV_L1_SSI'
    ;Spectrograms: ICON_L1_FUVA_SUBLIMB_RAW[*,60,*] and ICON_L1_FUVA_SUBLIMB_IMG[*,60,*]
  endif

  if step eq 5 or step eq 99 then begin
    ; L2 FUV nighttime
    del_data, '*'
    instrument = 'fuv'
    datal1type = ''
    datal2type = 'O-nighttime'
    icon_load_data, trange = trange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    tplot_names

    get_data, 'ICON_L2_FUVA_TANGENT_LAT', data=d, dlimits=dlimits
    store_data, 'ICON_L2_FUVA_TANGENT_LAT1', data={x:d.x, y:reform(d.y[*,3,*]), v:d.v2}, dlimits=dlimits
    ylim, 'ICON_L2_FUVA_TANGENT_LAT1', 0, 135

    get_data, 'ICON_L2_FUVA_SWP_VER_ALTITUDE_PROFILE', data=d, dlimits=dlimits
    store_data, 'ICON_L2_FUVA_SWP_VER_ALTITUDE_PROFILE1', data={x:d.x, y:reform(d.y[*,3,*]), v:d.v2}, dlimits=dlimits
    ylim, 'ICON_L2_FUVA_SWP_VER_ALTITUDE_PROFILE1', 0,135

    options, 'ICON_L2_FUV_SC_LAT', 'psym', 3
    options, 'ICON_L2_ORBIT_NUMBER', 'psym', 3

    options, 'ICON_L2_FUV_SC_LAT', 'ytitle', 'SC LAT !C'
    options, 'ICON_L2_ORBIT_NUMBER', 'ytitle', 'ORBIT NUMBER !C'
    options, 'ICON_L2_FUVA_TANGENT_LAT1', 'ytitle', 'TANGENT LAT 3 !C'
    options, 'ICON_L2_FUVA_SWP_VER_ALTITUDE_PROFILE1', 'ytitle', 'ALTITUDE PROFILE 3 !C'

    options, 'ICON_L2_ORBIT_NUMBER', 'yrange', [1480, 1580]

    tplot_options, 'title', 'ICON FUV L2 O-nighttime'
    tdegap, ['ICON_L2_FUVA_TANGENT_LAT1','ICON_L2_FUVA_SWP_VER_ALTITUDE_PROFILE1'], overwrite=1, /twonanpergap
    tplot, ['ICON_L2_FUV_SC_LAT', 'ICON_L2_ORBIT_NUMBER','ICON_L2_FUVA_TANGENT_LAT1','ICON_L2_FUVA_SWP_VER_ALTITUDE_PROFILE1']
    if save_image then makepng,img_path + '5_ICON_FUV_L2_nighttime'
    ;Spectrograms: ICON_L2_FUVA_TANGENT_LAT[3,*,*] and ICON_L2_FUVA_SWP_VER_ALTITUDE_PROFILE[3,*,*]
  endif

  if step eq 6 or step eq 99 then begin
    ; L2 FUV daytime
    del_data, '*'
    instrument = 'fuv'
    datal1type = ''
    datal2type = 'O-daytime'
    icon_load_data, trange = trange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    tplot_names

    options, 'icon_l2_FUV_daytime_ON2_retrieval_f107', 'psym', 3
    options, 'icon_l2_FUV_daytime_ON2_retrieval_latitude', 'psym', 3
    ylim, 'icon_l2_FUV_daytime_ON2_original_data', 0, 510
    ylim, 'icon_l2_FUV_daytime_ON2_model_altitudes', 0, 510

    options, 'icon_l2_FUV_daytime_ON2_retrieval_f107', 'ytitle', 'retrieval f107 !C'
    options, 'icon_l2_FUV_daytime_ON2_retrieval_latitude', 'ytitle', 'retrieval latitude !C'
    options, 'icon_l2_FUV_daytime_ON2_original_data', 'ytitle', 'original data !C'
    options, 'icon_l2_FUV_daytime_ON2_model_altitudes', 'ytitle', 'model altitudes !C'

    tplot_options, 'title', 'ICON FUV L2 O-daytime'
    tdegap, ['icon_l2_FUV_daytime_ON2_original_data','icon_l2_FUV_daytime_ON2_model_altitudes'], overwrite=1, /twonanpergap
    tplot, ['icon_l2_FUV_daytime_ON2_retrieval_f107', 'icon_l2_FUV_daytime_ON2_retrieval_latitude','icon_l2_FUV_daytime_ON2_original_data','icon_l2_FUV_daytime_ON2_model_altitudes']
    if save_image then makepng,img_path + '6_ICON_FUV_L2_daytime'
    ;Time series: ICON_L2_FUV_DAYTIME_ON2_RETRIEVAL_F107 and ICON_L2_FUV_DAYTIME_ON2_RETRIEVAL_LATITUDE
    ;Spectrograms: ICON_L2_FUV_DAYTIME_ON2_ORIGINAL_DATA and ICON_L2_FUV_DAYTIME_ON2_MODEL_ALTITUDES
  endif

  if step eq 7 or step eq 99 then begin
    ; L1 IVM
    del_data, '*'
    instrument = 'ivm'
    datal1type = '*'
    datal2type = ''
    icon_load_data, trange = trange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    tplot_names

    options, 'ICON_L1_IVM_A_NORTH_FOOTPOINT_FA_ECEF_X', 'psym', 3
    options, 'ICON_L1_IVM_A_SC_MLT', 'psym', 3

    options, 'ICON_L1_IVM_A_NORTH_FOOTPOINT_FA_ECEF_X', 'ytitle', 'NORTH FOOTPOINT !C FA ECEF X !C'
    options, 'ICON_L1_IVM_A_SC_MLT', 'ytitle', 'SC MLT !C'
    options, 'ICON_L1_IVM_A_RPA_currents', 'ytitle', 'RPA currents!C'

    get_data,'ICON_L1_IVM_A_LLA_i',data=d, dlimits=dlimits
    store_data,'ICON_L1_IVM_A_LLA_i_corrected',data={x:d.x,y:d.y,v:reform(d.v[0,*])},dlimits=dlimits
    options, 'ICON_L1_IVM_A_LLA_i_corrected', 'ytitle', 'LLA i !C'

    tplot_options, 'title', 'ICON IVM L1'
    tdegap, ['ICON_L1_IVM_A_RPA_currents','ICON_L1_IVM_A_LLA_i_corrected'], overwrite=1, /twonanpergap

    tplot, ['ICON_L1_IVM_A_NORTH_FOOTPOINT_FA_ECEF_X', 'ICON_L1_IVM_A_SC_MLT','ICON_L1_IVM_A_RPA_currents','ICON_L1_IVM_A_LLA_i_corrected']
    if save_image then makepng,img_path + '7_ICON_IVM_L1'
    ;Time series: ICON_L1_IVM_A_NORTH_FOOTPOINT_FA_ECEF_X and ICON_L1_IVM_A_SC_MLT
    ;Spectrograms: ICON_L1_IVM_A_RPA_CURRENTS and ICON_L1_IVM_A_LLA_I
  endif

  if step eq 8 or step eq 99 then begin
    ; L2 IVM
    del_data, '*'
    instrument = 'ivm'
    datalqtype = ''
    datal2type = '*'
    icon_load_data, trange = trange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    tplot_names

    options, 'ICON_L2_IVM_A_LONGITUDE', 'psym', 3
    options, 'ICON_L2_IVM_A_AP_POT', 'psym', 3

    options, 'ICON_L2_IVM_A_LONGITUDE', 'ytitle', 'LONGITUDE !C'
    options, 'ICON_L2_IVM_A_AP_POT', 'ytitle', 'AP POT !C'
    options, 'ICON_L2_IVM_A_EQU_MER_DRIFT', 'ytitle', 'EQU MER DRIFT !C'

    tplot_options, 'title', 'ICON IVM L2'
    ;tdegap, ['ICON_L2_IVM_A_LONGITUDE', 'ICON_L2_IVM_A_AP_POT'], overwrite=1

    tplot, ['ICON_L2_IVM_A_LONGITUDE', 'ICON_L2_IVM_A_AP_POT', 'ICON_L2_IVM_A_EQU_MER_DRIFT']
    if save_image then makepng,img_path + '8_ICON_IVM_L2'
    ;Time series: ICON_L2_IVM_A_LONGITUDE and ICON_L2_IVM_A_AP_POT
    ;Spectrograms: there are no 2D data in those files
  endif

  if step eq 9 or step eq 99 then begin
    ; L2 IVM and L1 FUV LWP
    del_data, '*'

    ; Load IVM
    instrument = 'ivm'
    datal1type = ''
    datal2type = '*'
    icon_load_data, trange = trange, instrument = instrument, datal1type = datal1type, datal2type = datal2type

    ; Loaf FUV
    instrument = 'fuv'
    datal1type = 'lwp'
    datal2type = ''
    icon_load_data, trange = trange, instrument = instrument, datal1type = datal1type, datal2type = datal2type

    ; Specify options
    options,'ICON_L2_IVM_A_LONGITUDE', 'psym', 3
    options, 'ICON_L1_FUVB_LWP_Raw_P0', 'ytitle', 'Raw P0 !C'
    options, 'ICON_L1_FUVB_Board_TEMP', 'yrange', [27.5,27.9]
    options,'ICON_L1_FUVB_Board_TEMP', 'psym', 3
    ylim, 'ICON_L1_FUVB_LWP_Raw*', 0, 255

    options, 'ICON_L1_FUVB_Board_TEMP', 'ytitle', 'FUV Board Temp !C'
    options, 'ICON_L1_FUVB_LWP_Raw_P0', 'ytitle', 'FUV Raw P0 !C'
    options, 'ICON_L2_IVM_A_AP_POT', 'ytitle', 'IVM AP POT !C'
    options, 'ICON_L2_IVM_A_EQU_MER_DRIFT', 'ytitle', 'IVM EQU MER DRIFT !C'

    ; Fill gaps with NaN
    tdegap, ['ICON_L1_FUVB_LWP_Raw_P0','ICON_L1_FUVB_LWP_PROF_P0_Error'], overwrite=1, /twonanpergap

    ;Plot
    tplot, ['ICON_L1_FUVB_Board_TEMP','ICON_L1_FUVB_LWP_Raw_P0','ICON_L2_IVM_A_AP_POT', 'ICON_L2_IVM_A_EQU_MER_DRIFT'],$
      title='FUV and IVM combined'
    if save_image then makepng,img_path + '9_ICON_FUV_IVM'

  endif

  print, 'icon_crib finished'
end
