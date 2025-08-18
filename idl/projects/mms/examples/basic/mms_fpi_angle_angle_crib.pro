;+
;
;  This crib sheet shows how to create FPI angle-angle plots from the distribution functions
;
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2023-08-14 12:44:51 -0700 (Mon, 14 Aug 2023) $
;$LastChangedRevision: 31998 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_fpi_angle_angle_crib.pro $
;-

; Burst-mode electrons
mms_fpi_ang_ang, '2015-10-16/13:06:59.985', species='e', data_rate='brst'
stop

; Burst-mode ions
mms_fpi_ang_ang, '2015-10-16/13:06:59.985', species='i', data_rate='brst'
stop

; Limit the energy range for the ions
mms_fpi_ang_ang, '2015-10-16/13:06:59.985', energy_range=[662, 1802.2], species='i', data_rate='brst'
stop

; subtract the bulk velocity prior to creating the PA-energy spectrogram
; note: this only affects the PA-energy spectra, not the azimuth vs zenith, 
; nor azimuth and zenith vs energy spectra
mms_fpi_ang_ang, '2015-10-16/13:06:59.985', species='i', data_rate='brst', /subtract_bulk
stop

; save the plots as postscript files
mms_fpi_ang_ang, '2015-10-16/13:06:59.985', /postscript, species='i', data_rate='brst'
stop

end