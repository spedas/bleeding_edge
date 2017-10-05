;+

;PROCEDURE:	divide_data

;PURPOSE:

;  Divides successive channels of SST data by powers of 'factor', to

;  separate the traces. Also, optionally, multiplies data by an overall factor,

;  'conv_factor', to convert units.

;

;INPUT:		in_name (string), the name of the input TPLOT variable
;			structure.
;               out_name (string), the name of the output TPLOT variable
;			structure.

;KEYWORDS:      factor (float), by which fluxes in successive channels are

;               	divided.
;		conv_factor (optional float), by which fluxes in all channels
;			are multiplied.
;

;CREATED BY:	Ted Freeman

;FILE:  divide_data.pro

;LAST MODIFIED:  @(#)divide_data.pro	1.2 99/09/01

;

;NOTES:	  "LOAD_3DP_DATA" and "GET_SPEC" must be called first.

;-



pro divide_data, in_name, out_name, factor = factor, conv_factor = conv_factor



if not keyword_set(factor) then factor = 10.0

if not keyword_set(conv_factor) then conv_factor = 1.0



get_data, in_name, data = in_data, dlimit = lim



N_time = n_elements(in_data.X)

N_channel = dimen2(in_data.Y)



factors = conv_factor * factor^(-dindgen(N_channel))

factor_matrix = replicate(1, N_time) # transpose(factors)



flux_div = factor_matrix * in_data.Y



store_data, out_name, data = {x:in_data.X, y:flux_div}, dlimit = lim



end

