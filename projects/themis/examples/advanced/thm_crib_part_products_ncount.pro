;+
;Procedure:
;  thm_crib_part_products_ncount
;
;Purpose:
;  Demonstrate removal of one count level from particle spectrograms.
;  Rather than masking/subtracting the raw data this will create
;  a second product in parallel: a mask that can be applied to the 
;  final product (i.e. the subtraction is applied after averaging 
;  the data instead of before) 
;
;See also:
;  thm_crib_part_combine_ncount
;  thm_crib_part_products
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-07-22 16:53:38 -0700 (Fri, 22 Jul 2016) $
;$LastChangedRevision: 21514 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_part_products_ncount.pro $
;-

;setup
probe='a'
datatype='peif'
trange=['2008-02-23','2008-02-24']
timespan,trange

;load data into structures
data = thm_part_dist_array(probe=probe,trange=trange,datatype=datatype)

;make a copy of the raw data and set all samples to N count per bin
;  -units are counts by default
n_counts = 1.0
thm_part_copy, data, data_n
thm_part_set_counts, data_n, n_counts

;create eflux spectrograms with orignal data and N-count data
;  -eflux units must be specified since data is in counts
thm_part_products, dist_arr=data, suffix='_orig', units='eflux'
thm_part_products, dist_arr=data_n, suffix='_n', units='eflux'

;subtract one-count spectrogram from original data
;  -make sure data remains > 0 
name = 'th'+probe+'_'+datatype+'_eflux_energy'
calc, ' "'+name+'" = "'+name+'_orig" - "'+name+'_n" > 0' 

;plot original vs subtracted
tplot, name + ['_orig','']

end