pro psp_load_rfs, files = files

  if n_elements(files) GT 0 then begin

    cdf2tplot, files, prefix = 'psp_fld_rfs_', verbose=4, /get_support

  end
  
  options, 'psp_fld_rfs_lfr_auto_avg_ch?', 'panel_size', 2
  options, 'psp_fld_rfs_lfr_auto_avg_ch?', 'yrange', [1.e4,2.e6]
  options, 'psp_fld_rfs_lfr_auto_avg_ch?', 'ylog', 1
  options, 'psp_fld_rfs_lfr_auto_avg_ch?', 'zlog', 1
  options, 'psp_fld_rfs_lfr_auto_avg_ch?', 'ystyle', 1
  options, 'psp_fld_rfs_lfr_auto_avg_ch?', 'ysubtitle', '[Hz]'
  options, 'psp_fld_rfs_lfr_auto_avg_ch?', 'ztitle', '[V2/Hz]'
   
  options, 'psp_fld_rfs_lfr_auto_avg_ch0', 'ytitle', 'LFR AUTO!CCH0'
  options, 'psp_fld_rfs_lfr_auto_avg_ch1', 'ytitle', 'LFR AUTO!CCH1'

  options, 'psp_fld_rfs_lfr_ch0_source', 'psym', 4
  options, 'psp_fld_rfs_lfr_ch0_source_string', 'tplot_routine', 'strplot'


end