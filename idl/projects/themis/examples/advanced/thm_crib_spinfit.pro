;+
;Procedure:
;  thm_crib_spinfit
;
;
;Purpose:
;  Demonstration of finding spin fit parameters for spinning data.
;  The FIT module calculates the E-Field and B-Field vectors by taking 32 points at equal angles
;  and fitting a sine wave least squares fit to the data. The best fit of the data is defined by the
;  formula: A + B*cos() + C*sin(). The module calculates the standard deviation of the fit
;  called Sigma, and the number of points remaining in the curve called N.
;
;
;Usage documentation for thm_spinfit
;    
;    Arguments:
;      required parameters:
;        var_name_in = tplot variable name containing data to fit
;    
;    Keywords:
;       sigma = If set, will cause program to output tplot variable with sigma for each period.
;       npoints = If set, will cause program to output tplot variable with number of points in fit.
;       spinaxis = If set, program will output a tplot variable storing the average over the spin axis dimension
;                for each time period.
;       median  = If spinaxis set, program will output a median of each period instead of the average.
;       plane_dim = Tells program which dimension to treat as the plane. 0=x, 1=y, 2=z. Default 0.
;       axis_dim = Tells program which dimension contains axis to average over. Default 0.  Will not
;                create a tplot variable unless used with /spinaxis.
;       min_points = Minimum number of points to fit.  Default = 5.
;       alpha = A parameter for finding fits.  Points outside of sigma*(alpha + beta*i)
;             will be thrown out.  Default 1.4.
;       beta = A parameter for finding fits.  See above.  Default = 0.4
;       phase_mask_starts = Time to start masking data.  Default = 0
;       phase_mask_ends = Time to stop masking data.  Default = -1
;       sun2sensor = Tells how much to rotate data to align with sun sensor.
;
;   Notes:
;    	 The module determines which data is more than xN * �N (sN = standard deviation) away from fit,
;       and removes those points and repeats the fit. The second time the standard deviation is
;       smaller so the tolerance is increased a bit. The tolerance xN varies with try as:
;       Alpha*NBeta, where A=1.4 and Beta=0.4 provide good results. The operation continues
;       until no points are outside the bounds and the process is considered convergent.
;
;
;Written by Katherine Ramer
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-03-04 14:34:06 -0800 (Wed, 04 Mar 2015) $
; $LastChangedRevision: 17089 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_spinfit.pro $
;-


;------------------------------------------------------------------------------
; FIT Ground Based SpinFit data example.
;------------------------------------------------------------------------------

; Setup
;-----------

; set probe
probe = 'a'

; set the timespan 
trange = '2008-01-01/' + ['10:00','13:00']
timespan, trange

; set a few TPLOT options.
tplot_title = 'THEMIS FIT Ground Based Spin Fit Examples'
tplot_options, 'title', tplot_title
tplot_options, 'xmargin', [ 15, 10]
tplot_options, 'ymargin', [ 5, 5]

; set the color table.
loadct2, 39

; load the raw data required to perform spin fit
thm_load_fgm, probe=probe, level=1, type='raw'
thm_load_efi, probe=probe, level=1, type='raw'
thm_load_state, probe=probe, /get_support_data


; Perform spin fit
;----------------

; perform spin fit on fgh data and have it return A, B, C fit parameters plus the
; standard deviation and number of points remaining in curve.

; fit magnetic field data
thm_spinfit, 'th'+probe+'_fgh', /sigma, /npoints

; fit electric field data
thm_spinfit, 'th'+probe+'_efp', /sigma, /npoints


; Now load on board spin fit data to compare.
;------------------------

; tha_fit_efit and tha_fit_bfit contain the A, B, C, sigma, and npoints values in an
; nx5 array for electric and magnetic fields, respectively.
thm_load_fit, probe=probe, level=2, datatype=['fit_efit', 'fit_bfit']

; split into separate variables for comparison
;   -note: the vectors in these variables appear to be out of order
;split_vec, 'th'+probe+'_fit_efit', suffix='_'+['a','b','c','sig','npoints']
;split_vec, 'th'+probe+'_fit_bfit', suffix='_'+['a','b','c','sig','npoints']

; list variables
;tplot_names, '*_' + ['a','b','c','sig','npoints']


end



