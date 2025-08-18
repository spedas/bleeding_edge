;+
; PROCEDURE:
;         thm_crib_flipbookify
;
; PURPOSE:
;         Crib sheet showing how to create flipbook-style figures and 
;         movies with your current tplot window and 2D ESA/SST slices
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-08-27 15:21:22 -0700 (Mon, 27 Aug 2018) $
; $LastChangedRevision: 25700 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_flipbookify.pro $
;-

trange = '2008-02-26/' + ['04:54','05:00']
probe = 'b'

thm_load_fgm, probe=probe, trange=trange, level='l2'
thm_load_esa, probe=probe, trange=trange, level='l2'

tplot, ['th'+probe+'_fgs_dsl', 'th'+probe+'_peib_velocity_gsm', 'th'+probe+'_peib_density', 'th'+probe+'_peib_en_eflux']
stop

; use the 'seconds' keyword to create a plot every 10 seconds
; the figures are saved in ~/flipbook/ (can be changed with the 'output_dir' keyword)
thm_flipbookify, datatype='peib', probe=probe, seconds=10
stop

; use the 'slices' keyword to change the rotation of the slices on the figures
thm_flipbookify, slices=['bv', 'perp', 'yz'], datatype='peib', probe=probe, trange=trange, xrange=[-1000, 1000], yrange=[-1000, 1000], time_step=10
stop

; use the /video keyword to create a video from the series of images
thm_flipbookify, slices=['bv', 'perp', 'yz'], species='e', probe=probe, trange=trange, /video, time_step=10
stop


end