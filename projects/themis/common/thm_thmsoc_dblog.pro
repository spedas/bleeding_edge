;+
;NAME:
; thm_thmsoc_dblog
;
;PURPOSE:
; Database logging facility for IDL scripts. Useful for server runs.
;
;CALLING SEQUENCE:
; spd_thmsoc_dblog
;
;INPUT:
; none
;
;KEYWORDS:
;   server_run: 1 for server run
;   process_name: the name of the calling procedure
;   severity: 1-2-3, severity 4-5 is not reported (good for testing)
;   str_message: explanation about the error
;   args: COMMAND_LINE_ARGS
;   testing: prints a message that this log record is due to testing
;
;OUTPUT:
; Database logging
;
;EXAMPLES:
;  Example of how thmsoc_dblog.php is called from ksh scripts:
;     thmsoc_dblog.php make_ae_index.ksh 1 "$msg"
;  Example of how to call spd_thmsoc_dblog:
;     thm_thmsoc_dblog, server_run=1, process_name='make_ae_index', severity='1', str_message='Error: GMAG cdf file not found'
;
;NOTES:
;  This script should only be used on server runs.
;  It is distributed as a part of SPEDAS so that logging from overview plots will compile without errors.
;
;HISTORY:
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2021-09-14 12:19:36 -0700 (Tue, 14 Sep 2021) $
;$LastChangedRevision: 30294 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_thmsoc_dblog.pro $
;-----------------------------------------------------------------------------------

pro thm_thmsoc_dblog, server_run=server_run, process_name=process_name, severity=severity, str_message=str_message, testing=testing, args=args
  compile_opt idl2
  
  if ~keyword_set(process_name) then process_name='test'
  if ~keyword_set(severity) then severity='5'
  if ~keyword_set(str_message) then str_message='Not set'

  if ~keyword_set(server_run) then server=0
  if keyword_set(testing) then str_message = 'Testing, please ignore!' + string(10B) + string(10B) + str_message
  if keyword_set(args) then str_message = str_message + string(10B) + string(10B) + 'Command line args: ' + args
  if server_run eq 1 then begin
    spawn, '"/usr/bin/php" "/disks/socware/thmsoc_dp_current/src/php/thmsoc_dblog.php" ' + process_name + ' ' + strtrim(string(severity),2) + ' "' + str_message + '"'
  endif

end