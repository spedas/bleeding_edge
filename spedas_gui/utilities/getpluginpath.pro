;+
;
;NAME: getpluginpath
;
;PURPOSE:
;  gets the path of the plugins directory in a cross platform way
;
;CALLING SEQUENCE:
;   getpluginpath,path
;
;OUTPUT:
;   path:  the path to the plugins directory
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-01-09 09:30:19 -0800 (Fri, 09 Jan 2015) $
;$LastChangedRevision: 16608 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/getpluginpath.pro $
;----------

pro getpluginpath,path

  ;get path of routine
 rt_info = routine_info('getpluginpath',/source)
 path = file_dirname(rt_info.path) + '/../plugins/'

end
