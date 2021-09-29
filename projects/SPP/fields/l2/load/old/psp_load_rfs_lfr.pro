pro psp_load_rfs_lfr, files = files

  if n_elements(files) GT 0 then begin

    cdf2tplot, files, prefix = 'psp_fld_rfs_lfr_', verbose=4, /get_support

  end
  
  options, 'psp_fld_rfs_lfr_auto_ch?', 'panel_size', 2
  options, 'psp_fld_rfs_lfr_auto_ch?', 'yrange', [1.e4,2.e6]
  options, 'psp_fld_rfs_lfr_auto_ch?', 'ystyle', 1
  options, 'psp_fld_rfs_lfr_auto_ch?', 'ysubtitle', '[Hz]'
  options, 'psp_fld_rfs_lfr_auto_ch?', 'ztitle', '[V2/Hz]'
   
  options, 'psp_fld_rfs_lfr_auto_ch0', 'ytitle', 'LFR AUTO!CH0'
  options, 'psp_fld_rfs_lfr_auto_ch1', 'ytitle', 'LFR AUTO!CH1'

end