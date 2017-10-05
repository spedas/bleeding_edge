;+
; Procedure: MVN_PFP_L0_FILE_READ   Routine for reading MAVEN L0 files
; Inputs (all optional)
; PATHNAME =   i.e. 'maven/dpu/prelaunch/ATLO/201?????_??????_atlo_l0.dat'   ; default
; FILE= 'filename'      ; full
; SOURCE=  structure similar to that produced by mvn_file_source()
;-
pro mvn_pfp_l0_file_read,file=file,pathname=pathname,source=source,clear=clear,trange=trange $
    ,sep=sep,apidstats=stats    ,pfdpu=pfdpu , mag=mag,  static=static, lpw=lpw, set_realtime=set_realtime,recorder_id=recorder_id
starttime = systime(1)
if keyword_set(recorder_id) then begin
 recorder,recorder_id,get_filename=file
 dprint, 'Using realtime recorder file: ',file
endif

file = mvn_pfp_file_retrieve(pathname,file=file,source=source)

;if not keyword_set(file) then begin
;   source = mvn_pfp_file_source(source)
;   if ~ keyword_set(pathname) then begin
;       dprint,'Pathname or filename is required!'
;       return
;   endif
;   file = file_retrieve(pathname,_extra=source)
;   dprint,dlevel=2,file,/phelp
;endif

;enable which instruments get loaded
if n_elements(stats)   ne 0 then mvn_apid_counter,reset=stats,set_realtime=0
if n_elements(sep)   ne 0 then mvn_sep_handler,reset=sep,set_realtime=0
if n_elements(mag)   ne 0 then mvn_mag_handler,reset=mag,set_realtime=0
if n_elements(pfdpu) ne 0 then mvn_pfdpu_handler,reset=pfdpu,set_realtime=0
if n_elements(static) ne 0 then mvn_sta_handler,reset=static
;if n_elements(lpw) ne 0 then mvn_lpw_handler,reset=lpw,set_realtime=0

dprint,dlevel=2,'Start Loading file '+file
mvn_spc_apid_file_read,file=file,trange=trange

dprint,'Data loaded in ',systime(1)-starttime,' seconds',dlevel=2


;Disable loading at the end and finish if needed
rt=keyword_set(set_realtime)
if 1 then begin
if n_elements(pfdpu) ne 0 then mvn_pfdpu_handler,reset=0,finish=1,set_realtime=rt
if n_elements(mag)   ne 0 then mvn_mag_handler,reset=0,finish=1,set_realtime=rt
if n_elements(sep)   ne 0 then mvn_sep_handler,reset=0,finish=1,set_realtime=rt        ; disables manager, but common block data remains intact
;if n_elements(lpw)   ne 0 then mvn_lpw_handler,reset=0,set_realtime=rt
if n_elements(static) ne 0 then mvn_sta_handler,reset=0
endif

dprint,'Finalization Done ',systime(1)-starttime,' seconds',dlevel=2


end

