FUNCTION eva_sitl_tfom, unix_FOMstr
  s = unix_FOMstr
  dtlast = s.TIMESTAMPS[s.NUMCYCLES-1]-s.TIMESTAMPS[s.NUMCYCLES-2]
  tfom = [s.timestamps[0], s.timestamps[unix_FOMstr.NUMCYCLES-1]+dtlast]
  
  ;tfom = [unix_FOMstr.timestamps[0], unix_FOMstr.timestamps[unix_FOMstr.NUMCYCLES-1]+10.d0]
  return, tfom
END