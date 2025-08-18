;+
;
; SPP_SWP_SPANX_SWEEP_TABLES
;
; KEYWORDS:
;
;     new_defl - Set to use calibrated deflector values.
;
; $LastChangedBy: rlivi04 $
; $LastChangedDate: 2022-03-14 15:55:56 -0700 (Mon, 14 Mar 2022) $
; $LastChangedRevision: 30677 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/tables/spp_swp_spanx_sweep_tables.pro $
;
;-

function spp_swp_spanx_sweep_tables,erange,deflrange,plot=plot,emode=emode,sensor=sensor,k=k,rmax=rmax,vmax=vmax,nen=nen,spfac=spfac,$
                                    maxspen=maxspen,hvgain=hvgain,spgain=spgain,fixgain=fixgain,new_defl=new_defl,spe=spe,version=version,$
                                    defl_lim=defl_lim
    
   if n_elements(erange) eq 2 then valid=1b else begin
      valid = 0b
      erange=[!values.f_nan,!values.f_nan]
   endelse

   ;;  max = 65536.

   if ~ isa(sensor)  then sensor  = 0
   if ~ isa(emode)  then emode  = 0
   if ~ isa(k)       then k       = 16.7
   if ~ isa(rmax)    then rmax    = 11.0
   if ~ isa(vmax)    then vmax    = 4000
   if ~ isa(nen)     then nen     = 128
   if ~ isa(spfac)   then spfac   = 0.
   if ~ isa(maxspen) then maxspen = 5000.
   if ~ isa(hvgain)  then hvgain  = 1000.
   if ~ isa(spgain)  then spgain  = 20.12
   if ~ isa(fixgain) then fixgain = 13.
   IF ~ isa(version) THEN version = 2
   
   ;; Define energy minimum and maximum
   emin = erange[0]
   emax = erange[1]

   ;; Version Description
   ;; 1: Oddly spaced targeted sweeps.
   ;; 2: Evenly spaced targeted sweeps.
   ;; 3: Targeted table that repeates 8 deflections for a single energy
   ;;
   ;; Default: Vesion 2

   ;; DACS
   spp_swp_sweepv_dacv_v2,sweepv_dac,defv1_dac,defv2_dac,spv_dac,k=k,rmax=rmax,vmax=vmax,nen=nen,e0=emin,emax=emax,spfac=spfac,$
                          maxspen=maxspen,version=version,plot=plot,hvgain=hvgain,spgain=spgain,fixgain=fixgain,new_defl=new_defl,spe=spe,defl_lim=defl_lim

   ;; Full Index
   spp_swp_sweepv_new_fslut_v2,sweepv,defv1,defv2,spv,fsindex,version=version,nen=nen/4,e0=emin,emax=emax,plot=plot,spfac=spfac,new_defl=new_defl,defl_lim=defl_lim

   ;; Targeted Index
   FOR i=0, 255 DO BEGIN
      spp_swp_sweepv_new_tslut_v2,version=version,sweepv,defv1,defv2,spv,fsindex_tmp,tsindex,plot=plot,nen=nen,e0=emin,emax=emax,edpeak=i,spfac=spfac,new_defl=new_defl,defl_lim=defl_lim
      IF i EQ 0 THEN index = tsindex ELSE index = [index,tsindex]      
   ENDFOR
   tsindex = index
   
   if 1 then begin
      timesort = indgen(8*32)
      defsort = indgen(8,2,16)
      for i = 0,15 do defsort[*,1,i] = reverse(defsort[*,1,i]) ; reverse direction of every other deflector sweep
      defsort = reform(defsort,8,32)                           ; defsort will reorder data so that it is no longer in time order - but deflector values are regular    
   endif else begin
      timesort = indgen(4,8*32)
      defsort = indgen(4*8,2,16)
      for i = 0,15 do defsort[*,1,i] = reverse(defsort[*,1,i]) ; reverse direction of every other deflector sweep
      defsort = reform(defsort,4,8,32)                         ; defsort will reorder data so that it is no longer in time order - but deflector values are regular
   endelse

   ;; Error Checking
   if total(/pres,(defv1_dac ne 0) and (defv2_dac ne 0)) then message,'Bad deflector sweep table'

   ;; Creat SPAN Structure
   sweep_params = {emin:emin,emax:emax,k:k,rmax:rmax,vmax:vmax,nen:nen,spfac:spfac,maxspen:maxspen,hvgain:hvgain,spgain:spgain,fixgain:fixgain }

   ;; Collect all information
   table = {emode:emode,sensor:sensor,hem_dac:sweepv_dac,def1_dac:defv1_dac,def2_dac:defv2_dac,spl_dac:spv_dac,fsindex:reform(fsindex,4,256),tsindex:reform(tsindex,256,256),$
            timesort: timesort,deflsort:defsort,sweep_params:sweep_params,valid:valid}

   return,table

END







;; Old Code

;;   ;; Initiate Table Constants
;;   nen=128
;;   emin=5.0
;;   emax=4000.
;;   k=16.7
;;   rmax=11.0
;;   vmax=4000
;;   maxspen=5000.
;;   hvgain=1000.
;;   spgain=20.12
;;   fixgain=13.
;;   sensor= 0
   
;;   if keyword_set(spane) then begin
;;    hvgain = 500.
;;    sensor = spane
;;   endif
;;   if n_elements(spfac) eq 0  then spfac = 0.
;;   if n_elements(emode) eq 0  then emode = 0
;;   

