setenv,'ROOT_DATA_DIR=Z:\maven_data\sep'
.compile mav_sep_dap_gse_msg_load
mav_sep_dap_misg_all_msg_load;, realtime=1
set_tplot_options


recorder ;128.32.98.65
;procedure is: 1) connect to stream, 2)click 'write to',
.compile mav_sep_dap_gse_msg_load
realtime = 1; 0 if archive data
.go

;to see Davin's fav plots
set_tplot_options
