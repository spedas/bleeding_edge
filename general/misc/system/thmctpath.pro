;+
;
;NAME: thmctpath
;
;PURPOSE:
;   Gets the path of the color table used by themis
;
;CALLING SEQUENCE:
;  thmctpath,getpath
; 
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2009-06-10 09:57:19 -0700 (Wed, 10 Jun 2009) $
;$LastChangedRevision: 6105 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/thmctpath.pro $
;----------

pro thmctpath, getpath = ctpathname

 
 ;is the path stored in an environment variable
 ctpathname = getenv('IDL_CT_FILE')
 
 if ~keyword_set(ctpathname) then begin
   rt_info = routine_info('thmctpath',/source)
   path = file_dirname(rt_info.path) + '/'
   ctpathname = path + 'colors1.tbl'
 endif

end
