; Test new FPI triggers
; 


timespan, '2015-12-14/22:30:00', 2, /hours

sc_id = 'mms2'

mms_sitl_get_fpi_trig, sc_id = sc_id

tplot, [sc_id + '_fpi_bentpipeB_DBCS', sc_id + '_fpi_bentPipeB_Norm', sc_id + '_fpi_pseudodens', $
  sc_id + '_fpi_epseudoflux', sc_id + '_fpi_epseudotemp', sc_id + '_fpi_ipseudovz', sc_id + '_fpi_ipseudovxy']

end