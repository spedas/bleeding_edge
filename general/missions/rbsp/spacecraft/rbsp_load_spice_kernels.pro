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
;   $LastChangedBy: kersten $
;   $LastChangedDate: 2013-01-30 16:10:32 -0800 (Wed, 30 Jan 2013) $
;   $LastChangedRevision: 11506 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/spacecraft/rbsp_load_spice_kernels.pro $
;-


pro rbsp_load_spice_kernels, verbose = verbose, unload=unload, all=all

rbsp_spice_init

metaprefix = 'teams/spice/mk'

relpathnames = metaprefix + '/rbsp_meta_general.tm'
;relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)
dprint,dlevel=3,verbose=verbose,relpathnames,/phelp
files = file_retrieve(relpathnames, _extra=!rbsp_spice)

rbsp_load_spice_metakernel,files[0],unload=unload,all=all

relpathnames = metaprefix + '/rbsp_meta_time.tm'
;relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)
dprint,dlevel=3,verbose=verbose,relpathnames,/phelp
files = file_retrieve(relpathnames, _extra=!rbsp_spice)

rbsp_load_spice_metakernel,files[0],unload=unload,all=all

relpathnames = metaprefix + '/rbsp_meta_definitive.tm'
;relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)
dprint,dlevel=3,verbose=verbose,relpathnames,/phelp
files = file_retrieve(relpathnames, _extra=!rbsp_spice)

rbsp_load_spice_metakernel,files[0],unload=unload,all=all

end