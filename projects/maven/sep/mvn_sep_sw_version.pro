;+
;NAME: MVN_SEP_SW_VERSION
;Function: mvn_spice_kernels(name)
;PURPOSE: 
; Acts as a timestamp file to trigger the regeneration of SEP data products. Also provides Software Version info for the MAVEN SEP instrument.  
;Author: Davin Larson  - January 2014
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2015-11-30 09:52:17 -0800 (Mon, 30 Nov 2015) $
; $LastChangedRevision: 19491 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sep/mvn_sep_sw_version.pro $
;-
function mvn_sep_sw_version

tb = scope_traceback(/structure)
this_file = tb[n_elements(tb)-1].filename   
this_file_date = (file_info(this_file)).mtime


sw_structure = {  $
  sw_version : 'v04' , $
  sw_time_stamp_file : this_file , $
  sw_time_stamp : time_string(this_file_date) , $
  sw_runtime : time_string(systime(1))  , $
  sw_runby :  getenv('LOGNAME') , $
  svn_changedby : '$LastChangedBy: davin-mac $' , $
  svn_changedate: '$LastChangedDate: 2015-11-30 09:52:17 -0800 (Mon, 30 Nov 2015) $' , $
  svn_revision : '$LastChangedRevision: 19491 $' }

return,sw_structure
end




