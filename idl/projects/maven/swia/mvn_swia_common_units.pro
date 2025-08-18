;+
;PROCEDURE: 
;	MVN_SWIA_COMMON_UNITS
;PURPOSE: 
;	Make tplot variables with moments from SWIA 3d data (coarse and/or fine), 
;	including average energy flux spectra
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE: 
;	MVN_SWIA_COMMON_UNITS, Units
;Inputs:
;	Units: Units to change all data in common block into
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2013-06-18 21:19:24 -0700 (Tue, 18 Jun 2013) $
; $LastChangedRevision: 12551 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_common_units.pro $
;
;-

pro mvn_swia_common_units, units

compile_opt idl2

common mvn_swia_data


if n_elements(swifs) gt 0 then begin
	nt = n_elements(swifs)
	
	if nt gt 0 then begin
		

		for i = 0,nt-1 do begin
			if i eq 0 then start = 1 else start = 0
			
			dat = mvn_swia_get_3df(index = i, start = start)
			
			dat = conv_units(dat,units)

			swifs[i].data = reform(dat.data,48,12,10)
			swifs[i].units = units

		endfor


	endif
endif

if n_elements(swifa) gt 0 then begin
	nt = n_elements(swifa)
	
	if nt gt 0 then begin
		

		for i = 0,nt-1 do begin
			if i eq 0 then start = 1 else start = 0
			
			dat = mvn_swia_get_3df(index = i, start = start,/archive)
			
			dat = conv_units(dat,units)

			swifa[i].data = reform(dat.data,48,12,10)
			swifa[i].units = units

		endfor


	endif
endif

if n_elements(swics) gt 0 then begin
	nt = n_elements(swics)
	
	if nt gt 0 then begin
		

		for i = 0,nt-1 do begin
			if i eq 0 then start = 1 else start = 0
			
			dat = mvn_swia_get_3dc(index = i, start = start)
			
			dat = conv_units(dat,units)

			swics[i].data = reform(dat.data,48,4,16)
			swics[i].units = units

		endfor


	endif
endif

if n_elements(swica) gt 0 then begin
	nt = n_elements(swica)
	
	if nt gt 0 then begin
		

		for i = 0,nt-1 do begin
			if i eq 0 then start = 1 else start = 0
			
			dat = mvn_swia_get_3dc(index = i, start = start, /archive)
			
			dat = conv_units(dat,units)

			swica[i].data = reform(dat.data,48,4,16)
			swica[i].units = units

		endfor


	endif
endif


if n_elements(swis) gt 0 then begin
	nt = n_elements(swis)
	
	if nt gt 0 then begin
		

		for i = 0,nt-1 do begin
			if i eq 0 then start = 1 else start = 0
			
			dat = mvn_swia_get_3ds(index = i, start = start)
			
			dat = conv_units(dat,units)

			swis[i].data = dat.data
			swis[i].units = units

		endfor


	endif
endif


end