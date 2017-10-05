;+
; NAME:
;     SOLARWIND_CRIB
;
; PURPOSE:
;	Crib sheet showing the use and work of the solar wind (SW) processing
;	routine.
;
; CATEGORY:
;	Crib sheet
;
; CALLING SEQUENCE:
;	solarwind_crib
;
; INPUTS:
;	none; the code prompts user to continue by entering .continue on terminal
;
; KEYWORDS:
;	none
;
; PARAMETERS: 3 parameters for outlier filtering and convolution are described
;		and set in the code remove_outliers.pro. Another parameter is set in
;		the auxillary routine remove_outliers_repair.pro. Time range for SW data
;		and time resolution of SW data are set in the crib code.
;
; OUTPUTS:
;	graphics, interactive terminal
;
; DEPENDENCIES: convolve_gaussian_1d.pro, remove_outliers.pro,
;     remove_outliers_repair.pro, wi_swe_load.pro, get_data.pro, xclip.pro,
;     xdegap.pro, xdeflag.pro, solarwind_load.pro, omni_hro_load.pro,
;     omni2_load.pro, wi_mfi_load.pro, solarwind_load_hro.pro,
;		solarwind_load_omni1h.pro, solarwind_load_wind.pro
;
; MODIFICATION HISTORY:
;	Written by:	Vladimir Kondratovich 2008/01/16.
;-
;
; THE CODE BEGINS:

pro solarwind_crib

startend=['2006-3-10','2006-3-11']
times=time_double(startend[0])
timee=time_double(startend[1])
trange=[times,timee]

print,'--- First output shows you what happens if you do not specify'
print,'--- the source of solar wind data. In this case you get a warning'
print,'--- message, keyword information, and the standard (SPDF) values'
print,'--- for Dp and Bz. The code output follows:'
print,' '


solarwind_load,swdata,dst,trange

plot,swdata[*,0]-swdata[0,0],swdata[*,1]

print,' '
print,'--- If you do not specify the SW data source, the code gives you'
print,'--- static values Dp=2.088 nPa (this graph) and Bz=0'
print,'--- Enter .c to see it.'
stop

plot,swdata[*,0]-swdata[0,0],swdata[*,2]

print,' '
print,'--- These values produce a "nominal" magnetopause boundary when'
print,'--- input to the common MP models. Output time grid covers uniformly the'
print,'--- input time range with 1000 points.'
print,' '
print,' '
print,'--- User can get WIND SW data by setting keyword "wind".'
print,'--- It is highly recommended to set, at the same time,'
print,'--- desired resolution of SW data. Otherwise, the data'
print,'--- will be given with a source resolution.'
print,'--- Every time the code cannot find data, it falls to above-described'
print,'--- standard case.'
print,' '
print,'--- Enter .c to get WIND Dp with resolution of 20 minutes'
stop

solarwind_load,swdata,dst,trange,resol=1200.,/wind
datawind20=swdata

plot,swdata[*,0]-swdata[0,0],swdata[*,1]

print,' '
print,'--- The code shifts WIND data in time to the bow-shock nose.'
print,'--- Enter .c to see the graph of Bz.'
stop

plot,swdata[*,0]-swdata[0,0],swdata[*,2]

print,' '
print,'--- The code can use High-Resolution OMNI (HRO) SW dataset,'
print,'--- which values are already propagated to the bow-shock nose.'
print,'--- Default option is to use HRO data with 1 minute resolution.'
print,'--- Keyword min5 allows you to use HRO data with 5 minute resolution.'
print,'--- Remember that the resolution of the output is set by '
print,'--- the keyword resol.'
print,' '
print,'--- Enter .c to get HRO Dp with resolution of 20 minutes'
stop

solarwind_load,swdata,dst,trange,resol=1200.,/hro
datahro20=swdata

plot,swdata[*,0]-swdata[0,0],swdata[*,1]

print,' '
print,'--- Enter .c to see the graph of HRO Bz.'
stop

plot,swdata[*,0]-swdata[0,0],swdata[*,2]

print,' '
print,'--- Third source of SW data is 1 hour OMNI-2 database (keyword h1).'

print,' '
print,'--- Enter .c to get OMNI-2 Dp (1-hour resolution)'
stop

solarwind_load,swdata,dst,trange,/h1
dataomni2=swdata
dstomni2=dst

plot,swdata[*,0]-swdata[0,0],swdata[*,1]

print,' '
print,'--- Enter .c to see the graph of OMNI-2 Bz.'
stop

plot,swdata[*,0]-swdata[0,0],swdata[*,2]

print,' '
print,'--- This database also supplies the Dst index.'
print,'--- Dst is returned at any call to the OMNI-2.'
print,'--- When you use another source of SW data, you can also get Dst'
print,'--- by setting keyword dst. In this case, Dst is interpolated onto the time'
print,'--- grid of the output (instead of native 1 hour grid).'
print,'--- Enter .c to see the graph of OMNI-2 Dst.'
stop

plot,swdata[*,0]-swdata[0,0],dstomni2

print,' '
print,'--- Let us compare SW data from all three sources.'
print,'--- Enter .c to see comparison for Bz.'
stop

plot,dataomni2[*,0]-dataomni2[0,0],dataomni2[*,2],line=1,/ynozero
oplot,datahro20[*,0]-dataomni2[0,0],datahro20[*,2],line=0
oplot,datawind20[*,0]-dataomni2[0,0],datawind20[*,2],color=250

print,' '
print,'--- White dotted - OMNI-2 1 hour.'
print,'--- White solid  - HRO 1 minute convolved to 20 min resolution.'
print,'--- Red solid  - WIND MFI convolved to 20 min resolution.'
print,' '
print,'--- Enter .c to see comparison for Dp.'
stop

plot,dataomni2[*,0]-dataomni2[0,0],dataomni2[*,1],line=1,/ynozero
oplot,datahro20[*,0]-dataomni2[0,0],datahro20[*,1],line=0
oplot,datawind20[*,0]-dataomni2[0,0],datawind20[*,1],color=250

print,' '
print,'--- Same color code.'
print,' '
print,'--- Enter .c to exit the crib.'
stop
print,' '
print,'crib_sw finished.'
end


