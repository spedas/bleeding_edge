;
;  $LastChangedBy: spfuser $
;  $LastChangedDate: 2018-09-07 15:53:01 -0700 (Fri, 07 Sep 2018) $
;  $LastChangedRevision: 25747 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_mag_hk/spp_fld_mag_hk_load_l1.pro $
;

pro spp_fld_mag_hk_load_l1, file, prefix = prefix, colors = colors

  cdf2tplot, file, prefix = prefix
  
  ; TODO: fix the TPLOT titles

  mag_hk_names = tnames(prefix + '*')
  
  foreach name, mag_hk_names do begin
    
    options, name, 'ynozero', 1
    options, name, 'psym_lim', 100
    options, name, 'symsize', 0.75
    options, name, 'colors', colors
    
  endforeach
  
  mag_hk_raw_names = tnames(prefix + '*_raw')

  foreach name, mag_hk_raw_names do begin
    
    options, name, 'ytickformat', '(I8)'
    
  endforeach

end