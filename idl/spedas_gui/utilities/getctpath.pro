;+
;
;NAME: getctpath
;
;PURPOSE:
;  gets the path of the color table on the file system 
;
;CALLING SEQUENCE:
;   getctpath,color_table_path
;
;OUTPUT:
;   color_table_path:  the path to the color table
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/getctpath.pro $
;----------

pro getctpath,ctpathname

  ;get path of routine
 rt_info = routine_info('getctpath',/source)
 path = file_dirname(rt_info.path) + '/../Resources/'
 ctpathname = path + 'spd_gui_colors.tbl'
 
end
