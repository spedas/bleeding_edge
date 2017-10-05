;+
;Procedure:
;  thm_crib_esa
;
;Purpose:
;  Demonstrate basice examples of accessing ESA particle data.
;  
;See also:
;  thm_crib_esa_bgnd_remove
;  thm_crib_part_products
;  thm_crib_part_slice2d
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-11-21 18:38:50 -0800 (Fri, 21 Nov 2014) $
;$LastChangedRevision: 16268 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/basic/thm_crib_esa.pro $
;
;-



;------------------------------------------------------------------------------
; Load all calibrated (l2) ground processed data products
;------------------------------------------------------------------------------

;time range 
trange = ['2010-02-13', '2010-02-14']

;probe
probe = 'b'

;load all data (by default level='l2') 
thm_load_esa, probe=probe, trange=trange

;list variables
tplot_names, '*pe??*'

stop

;------------------------------------------------------------------------------
; Load particular calibrated (l2) ground products
;------------------------------------------------------------------------------

;time range
trange = ['2010-02-13', '2010-02-14']

;probe
probe = 'b'

;specify output variables with datatype keyword (still defaults to l2 data)
thm_load_esa, probe=probe, trange=trange, datatype='peef_density peef_velocity_dsl peef_en_eflux'

;plot
tplot, 'th'+probe+'_'+['peef_density', 'peef_velocity_dsl', 'peef_en_eflux']

stop

;------------------------------------------------------------------------------
; Load all calibrated (l2) on-board data products
;------------------------------------------------------------------------------

;time range
trange = ['2010-02-13', '2010-02-14']

;probe
probe = 'b'

;load data
;  -must specify level 2 to get calibrated data
;  -there are no on board spectra
thm_load_mom, probe=probe, trange=trange, level='l2'

;plot
tplot, 'th'+probe+'_'+['peem_density', 'peem_velocity_dsl']

stop



;------------------------------------------------------------------------------
; Load raw (l0) data and generate moments
;------------------------------------------------------------------------------

;time range
trange = ['2010-02-13', '2010-02-14']

;probe
probe = 'b'

;data type
datatype='peif'

;Load raw, uncalibrated data into memory.
;This data can be accessed by various routines to produced data products.
thm_part_load, probe=probe, trange=trange, datatype=datatype

;Produce moments for specified data type
;  -background removal applied by default
;  -for more options see thm_crib_part_products
thm_part_products, probe=probe, trange=trange, datatype=datatype, output='moments'

;plot 
tplot, 'th'+probe+'_'+datatype+'_'+['density','eflux','t3']

stop

;------------------------------------------------------------------------------
; Load raw (l0) data and generate spectrograms
;------------------------------------------------------------------------------

;time range
trange = ['2010-02-13', '2010-02-14']

;probe
probe = 'b'

;data type
datatype='peif'

;Load raw, uncalibrated data into memory.
;This data can be accessed by various routines to produced data products.
thm_part_load, probe=probe, trange=trange, datatype=datatype

;Produce spectrograms for specified data type.
;  -only energy spectrogram is producted by default; others must be specified
;  -background removal applied by default
;  -for more options see thm_crib_part_products
thm_part_products, probe=probe, trange=trange, datatype=datatype, $
       output='energy phi theta'

;plot
tplot, 'th'+probe+'_'+datatype+'_eflux_'+['energy','phi','theta']

stop



end