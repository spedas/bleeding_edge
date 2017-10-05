;+
;
;NAME: getresourcepath
;
;PURPOSE:
;  gets the path of the resource directory in a cross platform way
;
;CALLING SEQUENCE:
;   getresourcepath,path
;
;OUTPUT:
;   path:  the path to the resource directory
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2015-06-25 11:06:01 -0700 (Thu, 25 Jun 2015) $
;$LastChangedRevision: 17971 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/getresourcepath.pro $
;----------

pro getresourcepath,path

  ;get path of routine
 rt_info = routine_info('getresourcepath',/source)
 path = file_dirname(rt_info.path) + PATH_SEP() + PATH_SEP(/PARENT_DIRECTORY) + PATH_SEP() + 'Resources' + PATH_SEP()

end
