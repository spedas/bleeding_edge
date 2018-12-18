;+
; Procedure: RBSP_LOAD_SPICE_KERNELS
;
; Purpose:  Loads RBSP SPICE kernels
;
; keywords:
;	/ALL : load all available kernels (default is to load kernels within 1 day
;			of the defined timespan)
;
; Examples:
;   rbsp_load_spice_kernels ; updates spice kernels based on MOC metakernels
;
; Notes:
;	Default behavior is to load all available kernels if no timespan is set.
;
;-
;
; History:
;	09/2012, created - Kris Kersten, kris.kersten@gmail.com
;	10/2012, substantially modified - Peter Schroeder, peters@ssl.berkeley.edu
;
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2018-12-17 13:57:14 -0800 (Mon, 17 Dec 2018) $
;   $LastChangedRevision: 26340 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/spacecraft/rbsp_load_spice_kernels.pro $
;-


pro rbsp_load_spice_kernels, verbose = verbose, unload=unload, all=all

  rbsp_spice_init
  rbsp_efw_init

  metaprefix = 'teams/spice/mk'


  ;------------------------------------------------------------------
  ;Load the meta general kernel. This one is not frequently updated
  ;------------------------------------------------------------------

  relpathnames = metaprefix + '/rbsp_meta_general.tm'


  ;extract the local data path without the filename
  localgoo = strsplit(relpathnames,'/',/extract)
  for i=0,n_elements(localgoo)-2 do $
    if i eq 0. then localpath = localgoo[i] else localpath = localpath + '/' + localgoo[i]
  localpath = strtrim(localpath,2) + '/'

  undefine,lf,tns
  dprint,dlevel=3,verbose=verbose,relpathnames,/phelp
  file_loaded = spd_download(remote_file=!rbsp_efw.remote_data_dir+relpathnames,$
    local_path=!rbsp_efw.local_data_dir+localpath,$
    local_file=lf,/last_version)
  files = !rbsp_efw.local_data_dir + localpath + lf

  rbsp_load_spice_metakernel,files[0],unload=unload,all=all



;------------------------------------------------------------------
;Load the meta time kernel. This one is updated frequently.
;------------------------------------------------------------------

  relpathnames = metaprefix + '/rbsp_meta_time.tm'


  ;extract the local data path without the filename
  localgoo = strsplit(relpathnames,'/',/extract)
  for i=0,n_elements(localgoo)-2 do $
     if i eq 0. then localpath = localgoo[i] else localpath = localpath + '/' + localgoo[i]
  localpath = strtrim(localpath,2) + '/'

  undefine,lf,tns
  dprint,dlevel=3,verbose=verbose,relpathnames,/phelp
  file_loaded = spd_download(remote_file=!rbsp_efw.remote_data_dir+relpathnames,$
     local_path=!rbsp_efw.local_data_dir+localpath,$
     local_file=lf,/last_version)
  files = !rbsp_efw.local_data_dir + localpath + lf


  rbsp_load_spice_metakernel,files[0],unload=unload,all=all


;------------------------------------------------------------------
;Load the meta definitive kernel. This one is frequently updated
;------------------------------------------------------------------

  relpathnames = metaprefix + '/rbsp_meta_definitive.tm'


  ;extract the local data path without the filename
  localgoo = strsplit(relpathnames,'/',/extract)
  for i=0,n_elements(localgoo)-2 do $
     if i eq 0. then localpath = localgoo[i] else localpath = localpath + '/' + localgoo[i]
  localpath = strtrim(localpath,2) + '/'

  undefine,lf,tns
  dprint,dlevel=3,verbose=verbose,relpathnames,/phelp
  file_loaded = spd_download(remote_file=!rbsp_efw.remote_data_dir+relpathnames,$
     local_path=!rbsp_efw.local_data_dir+localpath,$
     local_file=lf,/last_version)
  files = !rbsp_efw.local_data_dir + localpath + lf


  rbsp_load_spice_metakernel,files[0],unload=unload,all=all

end
