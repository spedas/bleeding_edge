;+
;NAME:
;   icon_crib_euv
;
;PURPOSE:
;   Example of loading and plotting ICON data for the EUV instrument
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
;$LastChangedDate: 2020-02-21 13:55:23 -0800 (Fri, 21 Feb 2020) $
;$LastChangedRevision: 28327 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/examples/icon_crib_euv.pro $
;
;-------------------------------------------------------------------

pro icon_crib_euv, step=step, img_path=img_path

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
    if (!D.NAME eq 'WIN') then img_path = 'C:\\temp\\icon\\' else img_path = 'temp/icon/'
  endif
  result = FILE_TEST(img_path, /directory, /read)
  save_image = 1
  if not result then begin
    save_image = 0
  endif

  ; Specify a time range
  trange = ['2010-05-21/23:58:00', '2010-05-22/00:02:00']

  cdf_leap_second_init

  if ~keyword_set(step) then step = 1

  if step eq 1 or step eq 99 then begin
    ;EUV level 1    
    ;trange = ['2020-01-11/23:58:00', '2020-01-12/00:02:00']
    del_data, '*'
    instrument = 'euv'
    datal1type = '*'
    datal2type = ''
    icon_load_data, trange = trange, instrument = instrument, datal1type = datal1type, datal2type = datal2type

    get_data, 'ICON_L1_EUV_Flux', data=d, dlimits=dlimits
    store_data, 'ICON_L1_EUV_Flux1', data={x:d.x, y:reform(d.y[*,5,*]), v:d.v2}, dlimits=dlimits

    tdegap, ['ICON_L1_EUV_Deadcor'], overwrite=1
    tdegap, ['ICON_L1_EUV_Spectrum','ICON_L1_EUV_Flux1'], overwrite=1, /twonanpergap

    ylim, 'ICON_L1_EUV_Deadcor', 0.95212D, 0.95216D
    options, 'ICON_L1_EUV_Deadcor', 'psym', 4
    options, 'ICON_L1_EUV_Deadcor', 'ytitle', 'EUV Deadcor!C'
    options, 'ICON_L1_EUV_Spectrum', 'ytitle', 'EUV Spectrum !C'
    options, 'ICON_L1_EUV_Flux1', 'ytitle', 'EUV Flux !C'

    options, 'ICON_L1_EUV_Deadcor', 'ysubtitle', ''

    tplot_options, 'title', 'ICON EUV'

    tplot, ['ICON_L1_EUV_Deadcor', 'ICON_L1_EUV_Spectrum', 'ICON_L1_EUV_Flux1']
    if save_image then makepng, img_path + '1_ICON_L1_EUV'

  endif

  if step eq 2 or step eq 99 then begin
    ;EUV level 2
    del_data, '*'
    instrument = 'euv'
    datal1type = ''
    datal2type = '*'
    icon_load_data, trange = trange, instrument = instrument, datal1type = datal1type, datal2type = datal2type

    options, 'ICON_L2_EUV_Daytime_OP_Retrieval_HmF2', 'ytitle', 'HmF2!C'
    options, 'ICON_L2_EUV_Daytime_OP_Retrieval_NmF2', 'ytitle', 'NmF2!C'
    options, 'ICON_L2_EUV_Daytime_OP_Retrieval_Oplus', 'ytitle', 'Oplus!C'
    options, 'ICON_L2_EUV_Daytime_OP_Input_Data_Brightness_834', 'ytitle', 'Brightness 834!C'
    options, 'ICON_L2_EUV_Daytime_OP_Input_Data_Din_617', 'ytitle', 'Din 617!C'

    ; Remove v-component from ICON_L2_EUV_Daytime_OP_SC_Position_ECEF
    get_data, 'ICON_L2_EUV_Daytime_OP_SC_Position_ECEF', data=d
    store_data, 'Position_ECEF', data={x:d.x, y:d.y}
    options, 'Position_ECEF', 'ytitle', 'Position!C'

    tplot_options, 'title', 'ICON EUV Level 2'

    tplot, ['ICON_L2_EUV_Daytime_OP_Retrieval_HmF2', 'ICON_L2_EUV_Daytime_OP_Retrieval_NmF2', 'Position_ECEF', $
      'ICON_L2_EUV_Daytime_OP_Retrieval_Oplus', 'ICON_L2_EUV_Daytime_OP_Input_Data_Brightness_834', 'ICON_L2_EUV_Daytime_OP_Input_Data_Din_617']
    if save_image then makepng, img_path + '1_ICON_L2_EUV'

  endif

  print, 'icon_crib_euv finished'
end