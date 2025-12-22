;+
;PROCEDURE:	make_efields_cdf
;PURPOSE:	
;	Make a cdf file with efields data	
;INPUT:		
;	data_str 
;		see NOTES, default 'DCEFS'
;
;
;KEYWORDS:
;	T1:		start time, seconds since 1970
;	T2:		end time, seconds since 1970		
;
;
;CREATED BY:	Ken Bromund	01/05/07
;VERSION:	1
;LAST MODIFICATION:  		01/05/07
;MOD HISTORY:
;
;
;NOTES:	
;  data_str:    'DCEFS'
;  sdt config:  Efields_Survey 
;  apids:	1032,1033
;  Fmodes:
;	
;  data_str:    'DCEF_4k'
;  sdt config:  Efields_4k_Burst
;  apids:	1054,1055
;  Fmodes:
;
;  data_str:	'DCEF_16k'
;  sdt config:  Efields_16k_Burst
;  apids:	1048,1049,1052,1054
;  Fmodes:

pro make_efields_cdf, data_str

; 
; Get the environment variables which set the output name and directory
; of the CDF
; This is for running under hires_cdf for batch hires cdf production

if n_params() eq 0 then data_str = 'DCEFS'

outputdir=getenv('IDL_HIRES_OUTDIR')
if outputdir eq '' then outputdir='.'
outputname=getenv('IDL_HIRES_CDFNAME')
if outputname eq '' then outputname = data_str+'.cdf'
help, outputdir
help, outputname

;Where are the DQD's? This assumes that all are loaded.

case strlowcase(data_str) OF
	'dcefs': begin
		fa_fields_despin, t1=t1, t2=t2
		e_near_b = 'E_NEAR_B'
		e_along_v = 'E_ALONG_V'
		end
	'dcef_4k': begin
		fa_fields_despin_4k ; takes non standard time=[t1, t2],
			            ; but since cdfhires doesn't pass any
				    ; time keywords at this point, I
				    ; will just leave this out for now.
		e_near_b = 'E_NEAR_B_4k'
		e_along_v = 'E_ALONG_V_4k'
		end
	'dcef_16k': begin
		fa_fields_despin_16k, t1=t1, t2=t2
		e_near_b = 'E_NEAR_B_16k'
		e_along_v = 'E_ALONG_V_16k'
		end
	ELSE: begin
		print, 'unknown data type: ', data_str
		return
		end
endcase

get_data, e_near_b, data=tmp

cdfdat0={time:tmp.x(0),e_near_b:tmp.y(0),e_along_v:tmp.y(0)}
cdfdat=replicate(cdfdat0,n_elements(tmp.x))

	cdfdat(*).time = tmp.x(*)
	cdfdat(*).e_near_b = tmp.y(*)

get_data, e_along_v, data=tmp
	cdfdat(*).e_along_v = tmp.y(*)

; leave out orbit data - resolution ridiculously high!

    makecdf,cdfdat,file=outputdir+'/'+outputname,overwrite=1


return


end
