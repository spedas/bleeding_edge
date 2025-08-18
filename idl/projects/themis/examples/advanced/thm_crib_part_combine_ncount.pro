
;+
;Name:
;  thm_crib_part_combine_ncount
;
;Purpose:
;  Crib demonstrating how to subtract or mask a set number of counts
;  from combined ESA-SST particle distributions.
;
;  Rather than masking/subtracting the raw data this will create
;  a second product in parallel: a mask that can be applied to the 
;  final product (i.e. the subtraction is applied after averaging 
;  and/or interpolating the data instead of before) 
;
;See also:
;  thm_crib_part_combine
;  thm_crib_part_products_ncount
;  thm_crib_part_slice2d
;  thm_crib_part_products
;
;Notes:
;  
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-07-22 16:53:38 -0700 (Fri, 22 Jul 2016) $
;$LastChangedRevision: 21514 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_part_combine_ncount.pro $
;-

compile_opt idl2


;--------------------------------------------------------------------------------------
;Load Combined Data
;--------------------------------------------------------------------------------------

;set probe and day
probe = 'd'
trange = '2011-07-29/' + ['13:00','14:00']

;specify datatypes
esa_datatype = 'peif'
sst_datatype = 'psif'


;Generate combined distribution
combined = thm_part_combine(probe=probe, trange=trange, $
                            esa_datatype=esa_datatype, $
                            sst_datatype=sst_datatype)

;Generate synthetic distribution
;  -all data will be set to the specified number of counts before  
;   it is interpolated
;  -this example uses 2 counts
base = thm_part_combine(probe=probe, trange=trange, $
                        esa_datatype=esa_datatype, $
                        sst_datatype=sst_datatype, $
                        set_counts=2)


stop


;--------------------------------------------------------------------------------------
;Create identical plots from real and synthetic data
;--------------------------------------------------------------------------------------

;produce 2d slices of 3D distribution along the GSM x-y axis
;  -limit energy range to exclude top SST energies
thm_part_slice2d, combined, slice_time=trange[0], timewin=30, $
                  erange=[0,4e5], coord='gsm', part_slice=slice

thm_part_slice2d, base, slice_time=trange[0], timewin=30, $
                  erange=[0,4e5], coord='gsm', part_slice=slice_base


;plot on constant z axis
zrange = [1e-17,1e-6]
thm_part_slice2d_plot, slice, window=0, zrange=zrange
thm_part_slice2d_plot, slice_base, window=1, zrange=zrange


stop


;--------------------------------------------------------------------------------------
;Plot masked and subtracted data
;--------------------------------------------------------------------------------------

;copy data to preserve original
masked = slice
subtracted = slice

;subtract synthetic data
;  -keep output > 0
subtracted.data = (slice.data - slice_base.data) > 0.  

;mask with synthetic data
;  -no change will be made if all real datapoints are larger
idx = where(slice.data lt slice_base.data, n)
if n gt 0 then masked.data[idx] = 0.


;plot
thm_part_slice2d_plot, slice, window=0, zrange=zrange, title='Original'
thm_part_slice2d_plot, subtracted, window=1, zrange=zrange, title='Subtracted'
thm_part_slice2d_plot, masked, window=2, zrange=zrange, title='Masked'



end