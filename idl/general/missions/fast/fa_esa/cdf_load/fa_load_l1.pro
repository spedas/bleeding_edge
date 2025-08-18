;Loads FAST Data
;/ORBIT keyword does not specify an orbit.  Orbits are specified by fa_orbitrange.
;/ORBIT keyword loads orbit CDF files into TPLOT variables.

pro fa_load_l1,datatype=datatype,type=type,orbit=orbit,_EXTRA=extra

if keyword_set(datatype) then type=datatype
if NOT keyword_set(type) then type=['ees','ies','eeb','ieb','seb1','seb2','seb3','seb4','seb5','seb6']
for iii=0,n_elements(type)-1 do begin
	case strlowcase(type[iii]) of
		'ees': fa_load_esa_l1,type='ees',_EXTRA=extra
		'ies': fa_load_esa_l1,type='ies',_EXTRA=extra
		'eeb': fa_load_esa_l1,type='eeb',_EXTRA=extra
		'ieb': fa_load_esa_l1,type='ieb',_EXTRA=extra
		'seb1': fa_load_seb_l1,type='seb1',_EXTRA=extra
		'seb2': fa_load_seb_l1,type='seb2',_EXTRA=extra
		'seb3': fa_load_seb_l1,type='seb3',_EXTRA=extra
		'seb4': fa_load_seb_l1,type='seb4',_EXTRA=extra
		'seb5': fa_load_seb_l1,type='seb5',_EXTRA=extra
		'seb6': fa_load_seb_l1,type='seb6',_EXTRA=extra
		'seb': fa_load_sesa_burst_l1,_EXTRA=extra
		'ses': fa_load_sesa_survey_l1,_EXTRA=extra
		else: print,'Error: '+type+' is an Invalid Type'
	endcase
endfor
;Note to Self: Modify fa_k0_load to use DATATYPE keyword?
if keyword_set(orbit) then fa_k0_load,'orb'

return
end