pro makesweapsweeptables, k = k, $
                          rmax = rmax, $
                          vmax = vmax, $
                          nen = nen, $
                          e0 = e0, $
                          emax = emax, $
                          spfac = spfac, $
                          maxspen = maxspen, $
                          plot = plot, $
                          hvgain = hvgain, $
                          spgain = spgain, $
                          fixgain = fixgain, $
                          edmask = edmask
  
  ;;---------------------------------------------
  ;; Set Keywords
  if not keyword_set(k)       then k       = 16.7
  if not keyword_set(rmax)    then rmax    = 11.0
  if not keyword_set(vmax)    then vmax    = 4000
  if not keyword_set(nen)     then nen     = 128 
  if not keyword_set(e0)      then e0      = 5.0
  if not keyword_set(emax)    then emax    = 20000.
  if not keyword_set(spfac)   then spfac   = 0.
  if not keyword_set(maxspen) then maxspen = 5000.
  if not keyword_set(hvgain)  then hvgain  = 1000.
  if not keyword_set(spgain)  then spgain  = 20.12
  if not keyword_set(fixgain) then fixgain = 13.
  if not keyword_set(edmask)  then edmask  = replicate(1,256)
  
  ;;------------------------------
  ;; Create Dac Values for S-LUT
  sweepv_dacv, sweepv_dac, $
               defv1_dac, $
               defv2_dac, $
               spv_dac, $
               k       = k, $
               rmax    = rmax, $
               vmax    = vmax, $
               nen     = nen, $
               e0      = e0, $
               emax    = emax, $
               spfac   = spfac, $
               plot    = plot, $
               maxspen = maxspen, $
               hvgain  = hvgain, $
               spgain  = spgain, $
               fixgain = fixgain


  ;;-----------------------
  ;; Load S-LUT File
  openw,1,'slut.txt'
  for i = 0,4095L do begin
     printf,1,spv_dac[i],  sweepv_dac[i],format = '(Z04,Z04)'
     printf,1,defv2_dac[i],defv1_dac[i], format = '(Z04,Z04)'
  endfor
  close,1

  ;;------------------------------
  ;; Create FS-LUT
  sweepv_new_fslut, sweepv, $
                    defv1, $
                    defv2, $
                    spv, $
                    index, $
                    nen = nen/4, $
                    plot = plot, $
                    spfac = spfac

  ;; 32-bit address is 2xindex
  index = long(index)           

  ;;-----------------------
  ;; Write FS-LUT Table  
  openw,1,'fslut.txt'  
  for i = 0,255 do begin
     printf,1,edmask[i]*2^12+index[i*4],edmask[i]*2^12+index[i*4+1], $
            format = '(Z04,Z04)'
     printf,1,edmask[i]*2^12+index[i*4+2],edmask[i]*2^12+index[i*4+3], $
            format = '(Z04,Z04)'
  endfor
  close,1
  
  ;;------------------------------
  ;; Create TS-LUT  
  for i = 0,255 do begin
     sweepv_new_tslut, sweepv, $
                       defv1, $
                       defv2, $
                       spv, $
                       fsindex, $
                       tsindex, $
                       nen = nen/4, $
                       edpeak = i, $
                       plot = plot, $
                       spfac = spfac
     if i eq 0 then index = tsindex else index = [index,tsindex]
  endfor
  
  ;; 32-bit address is 2xindex
  index = long(index)           
  
  ;;-----------------------
  ;; Write TS-LUT Table
  openw,1,'tslut.txt'  
  for i = 0,32767L do begin
     printf,1,index[i*2],index[i*2+1],format = '(Z04,Z04)'
  endfor
  close,1

end
