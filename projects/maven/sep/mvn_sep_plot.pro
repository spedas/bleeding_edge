
pro mvn_sep_plot,name,ADD=ADD,output_name=output_name,archive_ext=archive_ext

;if n_params() eq 0 then begin
;   mvn_sep_pfdpu_tplot_options
;   return
;endif
dprint,'This routine has been replaced by MVN_SEP_TPLOT.  Please update calling code.'

plot_name = strupcase(strtrim(name,2))
case plot_name of
'1':   tplot,'mvn_SEPS_hkp_VCMD_CNTR mvn_sep?_svy_DATA mvn_sep?_noise_SIGMA mvn_sep?_hkp_RATE_CNTR',ADD=ADD
'SUM': tplot,'mvn_SEPS_TEMP mvn_DPU_TEMP mvn_SEPS_svy_ATT mvn_sep?_svy_DATA mvn_sep?_noise_SIGMA mvn_sep?_hkp_RATE_CNTR',ADD=ADD
'SEPS':tplot,'mvn_SEPS_TEMP mvn_SEPS_svy_ATT mvn_SEPS_svy_COUNTS_TOTAL mvn_SEPS_hkp_VCMD_CNTR mvn_sep?_noise_SIGMA mvn_sep?_hkp_RATE_CNTR',ADD=ADD
'1A':  tplot,'mvn_sep1_A*',ADD=ADD
'1B':  tplot,'mvn_sep1_B*',ADD=ADD
'2A':  tplot,'mvn_sep2_A*',ADD=ADD
'2B':  tplot,'mvn_sep2_B*',ADD=ADD
'TID': tplot,'mvn_sep?_?_*tot',ADD=ADD
'FOIL':tplot,'mvn_sep?_?-F*',ADD=ADD
'OPEN':tplot,'mvn_sep?_?-O*',ADD=ADD
'THICK':tplot,'mvn_sep?_?-T*',ADD=ADD
'HKP': tplot,'mvn_sep?_hkp_AMON_*',ADD=ADD
'TEMP':tplot,'mvn_SEPS_TEMP mvn_DPU_TEMP',add=add
'NS1' : tplot,'mvn_sep1_noise_*',ADD=ADD
'MAG1': tplot,'mvn_mag1_svy_BRAW',ADD=ADD
'MAG2': tplot,'mvn_mag2_svy_BRAW',ADD=ADD
'QL' : tplot,'mvn_mag1_svy_BRAW* mvn_mag2_svy_BRAW* mvn_SEPS_QL mvn_pfdpu_oper_ACT_STATUS_FLAG mvn_lpw_euv*',add=add   ; example QL plot
else: dprint,'Unknown code: '+strtrim(name,2)
endcase

if not keyword_set(archive_ext) then archive_ext = '.arc'
if not keyword_set(archive_dir) then archive_dir = 'archive/'
if keyword_set(output_name) then begin
   file_name=output_name + '_'+plot_name
   file_archive,file_name+'.png',archive_ext=archive_ext,archive_dir=archive_dir
   makepng,window=0,file_name,/mkdir
 ;  file_chmod,file_name,/g_write
 ;  file_chmod,file_dirname(file_name),/g_write
endif

end
