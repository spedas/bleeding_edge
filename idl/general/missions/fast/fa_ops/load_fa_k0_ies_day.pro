;+
;PROCEDURE:	load_fa_k0_ies_day
;PURPOSE:	
;	Load daily summary data from the FAST ion experiment into tplot structure.
;
;		Loads ion_0	ion energy spectrogram, 0-30 pitch angle 
;		Loads ion_90	ion energy spectrogram, 40-140 pitch angle 
;		Loads ion_180	ion energy spectrogram, 150-180 pitch angle 
;		Loads ion_low	ion pitch angle spectrogram, .05-1 keV energy 
;		Loads ion_high	ion pitch angle spectrogram, > 1 keV energy 
;		Loads JEi	ion energy flux - mapped to 100 km, positive earthward 
;		Loads Ji	ion particle flux - mapped to 100 km, positive earthward 
;
;		Loads Attitude and Orbit data from the cdf file
;	
;INPUT:	
;	none 
;KEYWORDS:
;	filenames	strarr(m), string array of filenames of cdf files to be entered
;				Files are obtained from "dir" if dir is set, 
;					otherwise files obtained from local dir.
;				If filenames not set, then orbit or trange keyword must
;					be set.
;	dir		string, directory where filenames can be found
;				If dir not set, default is "environvar" or local directory
;	environvar	string, name of environment variable to set "dir"
;				Used if filenames not set
;				Default environvar = '$FAST_CDF_HOME'
;
;CREATED BY:	J. McFadden 97-04-03
;LAST MODIFICATION:  97-04-03
;MOD HISTORY:
;-

pro load_fa_k0_ies_day, $
	filenames=filenames, $
	dir = dir, $
	environvar = environvar

load_fa_k0_ies,filenames=filenames,dir=dir,environvar=environvar

loadcdf,filenames,'quality_flag',var
loadcdf,filenames,'unix_time',time
tmp={ytitle:'quality',x:time,y:var}
store_data,'quality',data=tmp
ylim,'quality',-1,2,0

loadcdf,filenames,'post_gap_flag',var
loadcdf,filenames,'unix_time',time
tmp={ytitle:'gap_flag',x:time,y:var}
store_data,'gap_flag',data=tmp
ylim,'gap_flag',-1,2,0

loadcdf,filenames,'spin_axis_ra',var
loadcdf,filenames,'unix_time',time
tmp={ytitle:'spin_axis_ra',x:time,y:var}
store_data,'spin_axis_ra',data=tmp

loadcdf,filenames,'spin_axis_dec',var
loadcdf,filenames,'unix_time',time
tmp={ytitle:'spin_axis_dec',x:time,y:var}
store_data,'spin_axis_dec',data=tmp

loadcdf,filenames,'r',var
loadcdf,filenames,'unix_time',time
tmp={ytitle:'r GEI',x:time,y:var}
store_data,'r',data=tmp

loadcdf,filenames,'v',var
loadcdf,filenames,'unix_time',time
tmp={ytitle:'v GEI',x:time,y:var}
store_data,'v',data=tmp

loadcdf,filenames,'alt',var
loadcdf,filenames,'unix_time',time
tmp={ytitle:'ALT',x:time,y:var}
store_data,'ALT',data=tmp

loadcdf,filenames,'flat',var
loadcdf,filenames,'unix_time',time
tmp={ytitle:'FLAT',x:time,y:var}
store_data,'FLAT',data=tmp

loadcdf,filenames,'flng',var
loadcdf,filenames,'unix_time',time
tmp={ytitle:'FLNG',x:time,y:var}
store_data,'FLNG',data=tmp

loadcdf,filenames,'mlt',var
loadcdf,filenames,'unix_time',time
tmp={ytitle:'MLT',x:time,y:var}
store_data,'MLT',data=tmp

loadcdf,filenames,'ilat',var
loadcdf,filenames,'unix_time',time
tmp={ytitle:'ILAT',x:time,y:var}
store_data,'ILAT',data=tmp


; Zero the time range

	tplot_options,trange=[0,0]

return
end
