;+
; NAME:
;     OUTLIERS_AND_CONVOLUTION_CRIB
;
; PURPOSE:
;	Crib sheet showing the use and work of the outlier removal and
;	convolution routines.
;
; CATEGORY:
;	Crib sheet
;
; CALLING SEQUENCE:
;	crib_outliers_and_convolution
;
; INPUTS:
;	none; the code prompts user to continue by entering .continue command
;
; KEYWORDS:
;	none
;
; PARAMETERS: 3 parameters for outlier filtering and convolution are described
;		and set in the code. Another parameter is set in the auxillary
;		routine remove_outliers_repair.pro
;
; OUTPUTS:
;	graphics
;
; DEPENDENCIES: convolve_gaussian_1d.pro, remove_outliers.pro, remove_outliers_repair.pro,
; wi_swe_load.pro, get_data.pro, xclip.pro, xdegap.pro, xdeflag.pro.
;
; MODIFICATION HISTORY:
;	Written by:	Vladimir Kondratovich 2007/12/28.
;-
;
; THE CODE BEGINS:

pro outliers_and_convolution_crib

;Parameters for outlier filtering:
;halfwidth of the hollow vicinity (in number of points)
d=3
;maximal comparison time
tmax=15 ;minutes
tmax=tmax*60 ;seconds
;tmax=double(tmax*1000.) ;milliseconds
;tmax=tmax/1440. ;MJD
;maximal deviation from the vicinity average deemed probable, in sdev
nmax=3
;Parameter defining how to fix an outlier (6 choices) is set in
; the auxillary routine remove_outliers_repair.pro

print,'Let first get some WIND data - scalar and vector arrays.'

;get data
trange=['2007-10-20','2007-10-21']
times=time_double(trange(0))
timee=time_double(trange(1))
wi_swe_load,trange=[times,timee]
get_data,'wi_swe_V_GSE',timeswe,vsw
get_data,'wi_swe_Np',timeswe,np

if n_elements(np) lt 10 then begin
   print,'Cannot get enough data. Please select another time interval.'
   return
endif

print,'Data downloaded. We have created scalar array NP and vector array VSW.'

print,'Retain only good values: replace fill values with NaNs'
print,'with TDAS code xclip.'
amm=0.999*max(abs(vsw))
xclip,-amm,amm,vsw
amm=0.999*max(abs(np))
xclip,-amm,amm,np

;make copies of unprocessed files
vswraw=vsw
npraw=np

print,'Remove outliers with remove_outliers.'
print,'The code remove_outliers accepts scalar and vector arrays.'
print,'You will see the reports below for each component of the vector array'
print,'and for the scalar array.'
remove_outliers,timeswe,vsw,d,tmax,nmax
remove_outliers,timeswe,np,d,tmax,nmax

print,'Compare improved data (white line) to original (red).'
print,'Scalar array NP'
plot,timeswe-timeswe(0),npraw,color=250,/ynozero
oplot,timeswe-timeswe(0),np
print,'Next is x-component of the vector VSW with the same color code.'
print,'Enter .c to get it'
stop

plot,timeswe-timeswe(0),vswraw(*,0),color=250,/ynozero
oplot,timeswe-timeswe(0),vsw(*,0)
print,'Next is y-component of the vector VSW with the same color code.'
print,'Enter .c to get it'
stop


plot,timeswe-timeswe(0),vswraw(*,1),color=250,/ynozero
oplot,timeswe-timeswe(0),vsw(*,1)
print,'Next is z-component of the vector VSW with the same color code.'
print,'Enter .c to get it'
stop

plot,timeswe-timeswe(0),vswraw(*,2),color=250,/ynozero
oplot,timeswe-timeswe(0),vsw(*,2)
print,'Now we will smoothen improved NP data to 30 min resolution'
print,'with our code convolve_gaussian_1d, which uses a Gaussian kernel.'
print,'In order to do it in a simple way, we have first'
print,'interpolate data on an equidistant time grid'
print,'with help of TDAS routines xdegap and xdeflag.'
print,'Enter .c to do all that.'
stop

;fill in the gaps
tswe=timeswe
delt=tswe-shift(tswe,1)
delt=delt(1:*)
dtswe=median(delt)
margswe=0.3*dtswe
xdegap,dtswe,margswe,tswe,np,tgridnp,npnan;,/nowarning
sss=size(npnan)
if sss(0) lt 1 then begin
   npnan=np
   tgridnp=tswe
endif

;interpolate onto the grid
fl=!values.f_nan
xdeflag,'linear',tgridnp,npnan,flag=fl
npgrid=npnan

;convolve to req'd resolution
resol=30*60.;sec
convolve_gaussian_1d,resol,tgridnp,npgrid,npconv

print,'Compare convolved NP data (white line) to the input (red).'
plot,tgridnp-timeswe(0),npgrid,color=250,/ynozero
oplot,tgridnp-timeswe(0),npconv
print,'Crib sheet finished.'
end
