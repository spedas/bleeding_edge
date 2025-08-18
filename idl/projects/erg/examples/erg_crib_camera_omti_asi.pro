;+
; PROGRAM: erg_crib_camera_omti_asi
;   This is an example crib sheet that will load OMTI ASI data.
;   Compile and run using the command:
;     .run erg_crib_camera_omti_asi
;
; NOTE: See the rules of the road.
;       For more information, see http://stdb2.isee.nagoya-u.ac.jp/omti/
;
; Written by: Y. Miyashita, Mar 28, 2013
;             ERG-Science Center, ISEE, Nagoya Univ.
;             erg-sc-core at isee.nagoya-u.ac.jp
;
;   $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
;   $LastChangedRevision: 26838 $
;-

; initialize
thm_init

; set the date and duration (in days)
timespan, '2012-09-04/10:00', 2, /hour

; set site and wavelength
site='drw'
wavelength=5577

; load data for the specified station and wavelenth
erg_load_camera_omti_asi, site=site, wavelength=wavelength, /timeclip

; view the loaded data names
tplot_names
stop

;--------------------------------------------------
; interactively show images for selected times
loadct, 0
window, 0, xsize=640, ysize=480
tplot, 'omti_asi_'+site+'_'+string(wavelength,format='(i4.4)')+'_image_raw'

get_data, 'omti_asi_'+site+'_'+string(wavelength,format='(i4.4)')+'_image_raw', data=imagedata
tvmin=min(imagedata.y) & tvmax=max(imagedata.y)
;tvmin=15000 & tvmax=25000

window, 1, xsize=n_elements(imagedata.y[0,*,0]), ysize=n_elements(imagedata.y[0,0,*])
options, 'omti_asi_'+site+'_'+string(wavelength,format='(i4.4)')+'_image_raw', irange=[tvmin,tvmax]
ctime, /cut    ; Use right button to exit
stop

; make PNG files
for i=0, n_elements(imagedata.y[*,0,0])-1 do begin
  ;tvscl, reform(imagedata.y[i,*,*])
  tvscl, bytscl(reform(imagedata.y[i,*,*]), min=tvmin, max=tvmax)

  makepng, site+'_'+string(wavelength,format='(i4.4)')+'_' $
          +strjoin(strsplit(time_string(imagedata.x[i]),'-/:',/extract))
endfor
stop

;--------------------------------------------------
; cloud information
get_data, 'omti_asi_'+site+'_cloud', data=dcloud, dlimits=dlcloud
window, 0, xsize=640, ysize=480
ylim, 'omti_asi_'+site+'_cloud', -1, 6, 0
tplot, ['omti_asi_'+site+'_cloud']
print, 'Hourly cloud information: ', dlcloud.cdf.vatt.var_notes

end
