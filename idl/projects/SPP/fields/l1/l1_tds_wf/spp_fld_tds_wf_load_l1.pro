pro spp_fld_tds_wf_load_l1, file, prefix = prefix, varformat = varformat

  ;
  ; TDS_wf files should have no prefix
  ;

  cdf2tplot, /get_support_data, file, varformat = varformat

end