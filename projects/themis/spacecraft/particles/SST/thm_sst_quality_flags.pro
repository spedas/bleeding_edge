;+
;Procedure:
;  thm_sst_quality_flags
;  
;Description:
;  makes a bitpacked tplot variable containing quality flags for SST
;  
;  Bit 0: saturated. (psef_count_rate > 10k)
;  Bit 1: attenuator error (stuck attenuator or incorrect indicator)
;  Bit 2: too low(<2.5 s) or too high(>5s) spin period
;  Bit 3: earth shadow
;  Bit 4: lunar shadow
;  
;  Set timespan by calling timespan outside of this routine.(e.g. time/duration is not an argument)
;  
; $LastChangedBy: jimm $
; $LastChangedDate: 2021-03-15 12:39:09 -0700 (Mon, 15 Mar 2021) $
; $LastChangedRevision: 29760 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/thm_sst_quality_flags.pro $
;-


  pro thm_sst_quality_flags,probe=probe,datatype=datatype
  
    compile_opt idl2
    
    thm_load_state,probe=probe,/get_support
    thm_load_sst,probe=probe
         
    get_data,'th'+probe+'_'+datatype+'_tot',data=d
      
    if is_struct(d) then begin
      bit0 = d.y gt 1e4
    endif else begin
      bit0 = 0
    endelse
    
    get_data,'th'+probe+'_'+datatype+'_atten',data=d
    
    if is_struct(d) then begin
      bit1 = (d.y ne 5) and (d.y ne 10)
;also flag all attenuator shifts, plus/minus 1, jmm, 2021-03-09
      ss_tr = where(d.y[1:*] Ne d.y[0:n_elements(d.y)-1], ntr)
;      ss_tr0 = ss_tr & bi10 = bit1 & bi10[ss_tr0] = 1
      If(ntr Gt 0) Then Begin
;flag the point before and the next point
         ss_tr = ([ss_tr, ss_tr+1] > 0) < (n_elements(d.y)-1)
         bit1[ss_tr] = 1
      Endif
    endif else begin
      bit1 = 0
    endelse
    ;state time abcissas won't match sst time abcissas by default 
    tinterpol_mxn,'th'+probe+'_state_spinper','th'+probe+'_'+datatype+'_tot',/overwrite
    get_data,'th'+probe+'_state_spinper',data=d
    
    if is_struct(d) then begin
      bit2 = (d.y lt 2.5) or (d.y gt 5)
    endif else begin
      bit2 = 0
    endelse
    
    tinterpol_mxn,'th'+probe+'_state_roi','th'+probe+'_'+datatype+'_tot',/overwrite,/nearest_neighbor
    get_data,'th'+probe+'_state_roi',data=d
    
    if is_struct(d) then begin
      bit3 = d.y and 1
      bit4 = ishft(d.y,-1) and 1
    endif else begin
      bit3 = 0
      bit4 = 0
    endelse
    
    flags = bit0 or ishft(bit1,1) or ishft(bit2,2) or ishft(bit3,3) or ishft(bit4,4)
    
    store_data,'th'+probe+'_'+datatype+'_data_quality',data={x:d.x,y:flags},dlimits={tplot_routine:'bitplot'}
  
  end
