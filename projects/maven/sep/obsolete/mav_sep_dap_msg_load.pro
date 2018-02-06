pro mav_sep_dap_msg_load



source = mav_file_source()

pathname = 'maven/sep/prelaunch_tests/EM1/20110302_113728_sample/misg_inst_msg.dat'

file = file_retrieve(pathname,_extra= source)

printdat,file_info(file)


end

