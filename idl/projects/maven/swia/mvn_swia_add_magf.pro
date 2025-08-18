;+
;PROCEDURE:	
;	MVN_SWIA_ADD_MAGF
;PURPOSE:	
;	Add magnetic field (in SWIA coordinates) to SWIA fine and coarse common blocks 
;
;INPUT:		
;
;KEYWORDS:
;	BDATA: tplot variable for the magnetic field 
;	(will be converted to 'MAVEN_SWIA' frame - so needs 'SPICE_FRAME' defined to work)
;
;AUTHOR:	J. Halekas	
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2015-02-03 17:28:45 -0800 (Tue, 03 Feb 2015) $
; $LastChangedRevision: 16846 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_add_magf.pro $
;
;-

pro mvn_swia_add_magf, bdata = bdata, verbose = verbose

;CHANGE: Get magnetic field at center time instead of start of sweep (better for SW)

compile_opt idl2

common mvn_swia_data

if not keyword_set(bdata) then bdata = 'mvn_B_1sec'

spice_vector_rotate_tplot,bdata,'MAVEN_SWIA',verbose=verbose

get_data,bdata+'_MAVEN_SWIA',data = bswia

if n_elements(swifs) gt 1 then begin
	ubx = interpol(bswia.y[*,0],bswia.x,swifs.time_unix+2.0)
	uby = interpol(bswia.y[*,1],bswia.x,swifs.time_unix+2.0)
	ubz = interpol(bswia.y[*,2],bswia.x,swifs.time_unix+2.0)

	magf = transpose( [[ubx],[uby],[ubz]] )

	str_element,swifs,'magf',magf,/add

endif

if n_elements(swifa) gt 1 then begin
	ubx = interpol(bswia.y[*,0],bswia.x,swifa.time_unix+2.0)
	uby = interpol(bswia.y[*,1],bswia.x,swifa.time_unix+2.0)
	ubz = interpol(bswia.y[*,2],bswia.x,swifa.time_unix+2.0)

	magf = transpose( [[ubx],[uby],[ubz]] )

	str_element,swifa,'magf',magf,/add

endif

if n_elements(swics) gt 1 then begin
	ubx = interpol(bswia.y[*,0],bswia.x,swics.time_unix+2.0)
	uby = interpol(bswia.y[*,1],bswia.x,swics.time_unix+2.0)
	ubz = interpol(bswia.y[*,2],bswia.x,swics.time_unix+2.0)

	magf = transpose( [[ubx],[uby],[ubz]] )

	str_element,swics,'magf',magf,/add

endif

if n_elements(swica) gt 1 then begin
	ubx = interpol(bswia.y[*,0],bswia.x,swica.time_unix+2.0)
	uby = interpol(bswia.y[*,1],bswia.x,swica.time_unix+2.0)
	ubz = interpol(bswia.y[*,2],bswia.x,swica.time_unix+2.0)

	magf = transpose( [[ubx],[uby],[ubz]] )

	str_element,swica,'magf',magf,/add

endif


end
