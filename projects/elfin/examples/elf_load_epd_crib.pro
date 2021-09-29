;+
; ELF EPD crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to clrussell@igpp.ucla.edu
;
;
; $LastChangedBy: clrussell $
; $LastChangedDate: 2016-05-25 14:40:54 -0700 (Wed, 25 May 2016) $
; $LastChangedRevision: 21203 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elf/examples/basic/mms_load_state_crib.pro $
;-

;;    ============================
;; 1) Select date and time interval
;;    ============================
; download data for 8/2/2015
date = '2019-09-28/00:00:00'
timespan,date,1,/day
tr = timerange()

;;    ===================================
;; 2) Select probe, datatype=electron
;;    ===================================
probe = 'a'         ; currently on ELFIN, only A data is available for EPD (B coming soon)
datatype = 'pef'    ; currently pef (electron fast mode) data is the only type available, pif coming soon
; Load EPD data
elf_load_epd, probes=probe, datatype=datatype, trange=tr
get_data, 'ela_pef_nflux', data=pef_nflux
help, pef_nflux
stop

timespan, '2020-01-08'
tr = timerange()
elf_load_epd, probes='a', datatype='pif', trange=tr, type='cps'
get_data, 'ela_pif_cps', data=pif_cps
help, pif_cps
stop


;;    ===================================
;; 3) Select one science zone, datatype=electron
;;    ===================================
timespan, '2020-11-21/01:07:00',360,/sec
tr = timerange()
elf_load_epd, probes='a', datatype='pef', trange=tr
tplot, 'ela_pef_nflux'
stop


;;    ===================================
;; 4) Select two datatypes=pef and pif
;;    ===================================
timespan, '2020-01-08'
tr = timerange()
elf_load_epd, probes='a', datatype=['pef','pif'], trange=tr
get_data, 'ela_pef_nflux', data=pef_nflux
get_data, 'ela_pif_nflux', data=pif_nflux
help, pef_nflux
help, pif_nflux
stop


;;    ===================================
;; 5) Select both probes, type raw
;;    ===================================
elf_load_epd, probes=['a','b'], datatype='pef', trange=tr, type='raw'
get_data, 'ela_pef_raw', data=ela_pef_raw
get_data, 'elb_pef_raw', data=elb_pef_raw
help, ela_pef_raw
help, elb_pef_raw
stop

;;    ===================================
;; 6) Select probe, type calibrated (default)
;;    ===================================
timespan, '2019-01-05'
tr = timerange()
elf_load_epd, probes='a', datatype='pef', trange=tr, type='cal'
stop


;;    ===================================
;; 7) Select probe b and add a suffix
;;    ===================================
timespan, '2019-09-28'
tr = timerange()
elf_load_epd, probes='b', datatype='pef', trange=tr, type='nflux', suffix='_test'
get_data, 'elb_pef_nflux_test', data=d
help, d
stop

;;    ===================================
;; 8) Select both probes and datatypes
;;    ===================================
timespan, '2019-07-26'
tr = timerange()
elf_load_epd, probes=['a','b'], datatype=['pef' ,'pif'], trange=tr
tplot_names
print, '-----------------------------------------------------------------'
print, 'Note all EPD tplot vars contain the sector number and spin period'
print, '-----------------------------------------------------------------'
stop
get_data, 'ela_pef_sectnum', data=ela_pef_sectnum
get_data, 'elb_pif_spinper', data=elb_pif_spinper
help, ela_pef_sectnum
help, elb_pif_spinper
stop

;;    ===================================
;; 9) Use no_download keyword
;;    ===================================
timespan, '2019-07-26'
tr = timerange()
elf_load_epd, probes=['a','b'], datatype=['pef' ,'pif'], trange=tr, /no_download
print, '-----------------------------------------------------------------'
print, 'Note the messages in the console window show the data was loaded from the'
print, 'local disk and not from the remote server'
print, '-----------------------------------------------------------------'
stop

; remove tplot variables created so far
del_data, 'ela_p*f'

end