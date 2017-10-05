;  from IDL prompt type:  .run mvn_pfp_file_test_crib

dprint, /print_dtime, /print_time, print_trace=4, /print_dlevel  
printdat,mvn_file_source(VERBOSE=4, /FORCE_DOWNLOAD, NO_UPDATE=0 ,/SET)   ; Sets VERBOSE to level 4 for file retrieval subroutines. Forces download


dprint,'Start download'
files = mvn_pfp_file_retrieve(/L0,trange='2014-05-05')
dprint,'End download'

printdat,mvn_file_source(/RESET)
dprint,'Done'

libs,'mvn_file_source'
libs,'mvn_pfp_file_retrieve'
libs,'file_http_copy'
libs,'file_retrieve'

end
