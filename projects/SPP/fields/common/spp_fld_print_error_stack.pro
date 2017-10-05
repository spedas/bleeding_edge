;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2017-04-18 14:29:39 -0700 (Tue, 18 Apr 2017) $
;  $LastChangedRevision: 23183 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/common/spp_fld_print_error_stack.pro $
;
pro spp_fld_print_error_stack,err, stream_id

  ErrorBuffSize = 2500
  print, "Error = ", err
  err = TM_Error_Stack(stream_id, "name", ErrorDump, ErrorBuffSize, size)
  print, "Error Name = ", ErrorDump
  err = TM_Error_Stack(stream_id, "description", ErrorDump, ErrorBuffSize, size)
  print, "Error Description = ", ErrorDump
  err = TM_Error_Stack(stream_id, "message", ErrorDump, ErrorBuffSize, size)
  print, "Error Message = ", ErrorDump
  err = TM_Error_Stack(stream_id, "code", ErrorDump, ErrorBuffSize, size)
  print, "Error Code = ", ErrorDump

end
