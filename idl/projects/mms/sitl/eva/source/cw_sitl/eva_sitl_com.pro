;+
;COMMON BLOCK:  eva_sitl_com
;
;   sg:        structure for handling graphic objects used in the dashboard
;   fom_stack: array of pointers for handling stack history of D obtained by 
;              get_data, 'mms_stlm_output_fom',data=D
;   i_fom_stack: an interger for handling the point of stacking history.
;   n_highlight: highlight counter
;
;-
common eva_sitl_com, sg, fom_stack, i_fom_stack, old_polygonx, old_polygony, old_tstart, old_tend