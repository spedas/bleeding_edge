PRO eva_data_load_mms_fpi_ql_old, prb=prb, datatype=datatype
  compile_opt idl2
  
  mms_load_fpi, probes = prb, level='ql', data_rate='fast', datatype=datatype
  

  tngap = tnames('*_'+datatype+'_*')
  tdegap,  tngap, /overwrite
  spc = strmatch(datatype,'des') ? 'e':'i'
  
  ;---------------
  ; Spectrogram
  ;---------------
  carr = ['_omni_avg','_par','_perp']
  carr2= ['omni','para','perp']
  carr3= ['_E','_e','_e']
  cmax = n_elements(carr)
  for c=0,cmax-1 do begin
    tn = tnames('mms'+prb[0]+'_'+datatype+carr3[c]+'nergySpectr'+carr[c],ct)
    if ct eq 1 then begin
      options, tn,spec=1,ylog=1,zlog=1,no_interp=1, $
        ytitle='mms'+prb[0]+'!CFPI-'+spc+'!C'+carr2[c],ysubtitle='[eV]'
      ylim, tn, 10, 26000
    endif
  endfor
  
  ;----------
  ; PAD
  ;----------
  carr = ['low','mid','high']
  cmax = n_elements(carr)
  for c=0,cmax-1 do begin
    tn = tnames('mms'+prb[0]+'_'+datatype+'_pitchAngDist_'+carr[c]+'En',ct)
    if ct eq 1 then begin
      options, tn, spec=1,ylog=0,zlog=1,no_interp=1,$
        ytitle='mms'+prb[0]+'!CFPI-'+spc+'!CPAD',ysubtitle=carr[c]+'-E'
      ylim, tn,0,180
    endif
  endfor

  ;----------------
  ; NUMBER DENSITY
  ;----------------
  
  options, 'mms'+prb[0]+'_'+datatype+'_numberDensity', ylog=0,$
    ytitle='mms'+prb[0]+'!CFPI!CN'+spc,ysubtitle='[cm!U-3!N]'
  
  ;----------------------
  ; VECTOR QUANTITIES
  ;----------------------
  prefix = 'mms'+prb[0]+'_'+datatype
  join_vec, prefix+['_bulkX', '_bulkY', '_bulkZ'], prefix+'_bulk'
  options, prefix+'_bulk',labels=['x','y','z'],labflag=-1,colors=[2,4,6],$
    ytitle='mms'+prb[0]+'!CFPI!CV'+spc,ysubtitle='[km/s]',constant=0
  

END
