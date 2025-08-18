;+
;NAME:
; thm_spinmodel__define
;PURPOSE:
; define, construct, and destroy spinmodel objects
;-

pro thm_spinmodel__cleanup
  ptr_free,self.segs_ptr
  ptr_free,self.spincorr_times
  ptr_free,self.spincorr_vals
  return
end



function thm_spinmodel::init,probe=probe,suffix=suffix,midfix=midfix,eclipse=eclipse

   ;print,'obj before'
   ;help,self,/obj
   sname=probe

   self.probe=probe
   self.lastseg = -1L  ; Signifies that no segments have been added yet.
   ;
   ; Extract data from tplot variables

   ; JWL 2008-07-25 
   ;
   ; When loading spinmodel data from the state CDF rather than the spin CDF,
   ; there will be a midfix component '_state' immediately following
   ; the probe name in all the tplot variables.  This needs to be accounted 
   ; for here, by checking the existence of the 'midfix' keyword and IDL variable.
   ;

   if (n_elements(midfix) EQ 0) then begin
      munge='' 
   endif else begin
      munge=midfix
   endelse

   if (n_elements(suffix) EQ 0) then begin
      munge2='' 
   endif else begin
      munge2=suffix
   endelse

;  Default to standard model if eclipse keyword not used

   if (n_elements(eclipse) EQ 0) then eclipse=0

; If eclipse==1 or eclipse==2, use the "ecl" set of variables from the
; state CDF

   if (eclipse EQ 0) then begin
      munge3=''
   endif else begin
      munge3='ecl_'
   endelse
   prefix='th' + sname + munge + '_spin_' + munge3
   std_prefix='th' + sname + munge + '_spin_'
   spinper_var=prefix + 'spinper' + munge2
   time_var=prefix + 'time' + munge2
   tend_var=prefix + 'tend' + munge2
   c_var=prefix + 'c'+ munge2
   nspins_var=prefix + 'nspins' + munge2
   npts_var=prefix + 'npts' + munge2
   maxgap_var=prefix + 'maxgap' + munge2
   phaserr_var=prefix + 'phaserr' + munge2

   ; There is only one spin correction variable, and it doesn't have
   ; an '_ecl_' infix, so we need to use the standard variable
   ; name even if we're making an eclipse spin model.
   spincorr_var=std_prefix + 'correction' + munge2

   initial_delta_phi_var=prefix + 'initial_delta_phi' + munge2
   idpu_spinper_var=prefix + 'idpu_spinper' + munge2
   segflags_var=prefix + 'segflags' + munge2
   fgm_corr_tend_var=prefix + 'fgm_corr_tend' + munge2
   fgm_corr_offset_var=prefix + 'fgm_corr_offset' + munge2

   get_data,tend_var,tstart,tend,index=n
   if (n EQ 0) then begin
     dprint,'spinmodel_post_process: tplot variable not found: '+tend_var
     ;message, name='thm_spinmodel_post_process_no_tvar', block='spinmodel_post_process', $
     ;        tend_var
     return, 0
   endif
   get_data,spinper_var,dummy,spinper,index=n
   if (n EQ 0) then begin
     dprint,'spinmodel_post_process: tplot variable not found: '+spinper_var
    ; message, name='thm_spinmodel_post_process_no_tvar', block='spinmodel_post_process', $
    ;          spinper_var
    return, 0
   endif
   get_data,c_var,dummy,c,index=n
   if (n EQ 0) then begin
     dprint,'spinmodel_post_process: tplot variable not found: '+c_var
     ;  message, name='thm_spinmodel_post_process_no_tvar', block='spinmodel_post_process', $
     ;           c_var
     return, 0
   endif
   get_data,nspins_var,dummy,nspins,index=n
   if (n EQ 0) then begin
      dprint,'spinmodel_post_process: tplot variable not found: '+nspins_var
     ;  message, name='thm_spinmodel_post_process_no_tvar', block='spinmodel_post_process', $
     ;           nspins_var
     return, 0;
   endif
   get_data,npts_var,dummy,npts,index=n
   if (n EQ 0) then begin
     dprint,'spinmodel_post_process: tplot variable not found: '+npts_var
   ;  message, name='thm_spinmodel_post_process_no_tvar', block='spinmodel_post_process', $
   ;           npts_var
     return, 0
   endif
   get_data,maxgap_var,dummy,maxgap,index=n
   if (n EQ 0) then begin
     dprint,'spinmodel_post_process: tplot variable not found: '+maxgap_var
     ;message, name='thm_spinmodel_post_process_no_tvar', block='spinmodel_post_process', $
     ;         maxgap_var
     return, 0
   endif
   get_data,phaserr_var,dummy,phaserr,index=n
   if (n EQ 0) then begin
     dprint,'spinmodel_post_process: tplot variable not found: '+phaserr_var
   ;  message, name='thm_spinmodel_post_process_no_tvar', block='spinmodel_post_process', $
   ;           phaserr_var
     return, 0
   endif

   ; Spin phase correction: if missing, not considered an error, just
   ; assume 0.0 for all times.  Note that the spin correction has its
   ; own time variable (currently just a single sample in each daily CDF).

   get_data,spincorr_var,tp_spincorr_times,tp_spincorr_vals,index=n
   if (n EQ 0) then begin
     ; If spin phase correction variable is not present, use dummy values  
     dprint,'Using dummy values for spin phase correction'
     tp_spincorr_times=[0.0D,1.0D]
     tp_spincorr_vals=[0.0,0.0]
   endif else begin
     dprint,'Found spin phase correction variables'
   endelse

   ; 
   self.spincorr_times = ptr_new(tp_spincorr_times)
   self.spincorr_vals = ptr_new(tp_spincorr_vals)

   ; Eclipse delta_phi correction variables.  For testing purposes, 
   ; they might be missing (until new state CDFs are moved to production),
   ; in which case we supply default values.

   get_data,initial_delta_phi_var,dummy,initial_delta_phi,index=n_delta_phi
   get_data,idpu_spinper_var,dummy,idpu_spinper,index=n_idpu_spinper
   get_data,segflags_var,dummy,segflags,index=n_segflags

   if ( (n_delta_phi EQ 0) OR (n_idpu_spinper EQ 0) OR (n_segflags EQ 0)) then begin
      dprint,'Eclipse delta-phi variables not found, using defaults.'
      initial_delta_phi = dblarr(n_elements(tstart))
      idpu_spinper = dblarr(n_elements(tstart))
      segflags = intarr(n_elements(tstart))
   endif else begin
      dprint,'Eclipse delta-phi variables successfully loaded.'
   endelse

   get_data,fgm_corr_tend_var,data=fgm_corr_tend,index=n_fgm_corr_tend
   get_data,fgm_corr_offset_var,data=fgm_corr_offset,index=n_fgm_corr_offset
   
   ;help,tstart
   ;help,tend
   ;help,spinper
   ;help,c
   ;help,nspins
   ;help,npts
   ;help,maxgap

   ; Determine number of segments to make.  

   seg_count=n_elements(tstart)

   ; get_data always returns at least one element, so how do we
   ; figure out if tplot variables exist, but are empty?
   ; In that case, get_data returns a scalar value of 0.
   ; 0 is not a valid value for spinper, so that's our test.

   if (spinper[0] EQ 0) then begin
     mymsg='spinper[0] = 0 for probe ' + sname + ', probably due to empty tplot variable.'
     dprint,mymsg
     ;message, name='thm_spinmodel_post_process_zero_spinper', block='spinmodel_post_process', $
     ;         sname
     return, 0
   endif


   ; Seams may require insertion of additional segments

   if (seg_count GT 1) then begin
      shifted_array=tstart[1:seg_count-1]
      seams=where(shifted_array NE tend,seamcount)
   endif else begin
      seamcount=0
   endelse
   ;print,seamcount,' seams found.'
   rec_count=seg_count
   seg_count = seg_count + seamcount
   self.capacity = seg_count
   ;for i = 0L,seamcount-1L,1L do begin
   ;  print,FORMAT='(F20.8, F20.8, E20.6)',tstart[seams[i]+1],tend[seams[i]],$
   ;        tstart[seams[i]+1]-tend[seams[i]]
   ;endfor

   ; Make segment array

   segs = replicate({spinmodel_segment, t1:0.0D, t2:0.0D, c1:0L, c2:0L,$
          b:120.0D, c:0.0D, npts:0L, maxgap:0.0D, phaserr:0.0D,$
          initial_delta_phi:0.0D, idpu_spinper:0.0D, segflags: 0L},$
          seg_count)

   self.segs_ptr = ptr_new(segs)

   for i = 0L,rec_count-1L,1L do begin
      nextseg={spinmodel_segment,t1:tstart[i], t2:tend[i], c1:0L, c2:nspins[i],$
           b:360.0D/spinper[i], c:c[i], npts:npts[i], maxgap: maxgap[i],$
           phaserr:phaserr[i],initial_delta_phi:initial_delta_phi[i],$
           idpu_spinper:idpu_spinper[i],segflags:segflags[i]}
      self->addseg,nextseg
   endfor

   if ( (n_fgm_corr_tend EQ 0) OR (n_fgm_corr_offset EQ 0) OR (eclipse NE 2)) then begin
      dprint,'No FGM pseudo-DSL offset corrections applied.'
   endif else begin
      dprint,'Applying FGM pseudo-DSL offset corrections.'

      ; Each sample in the fgm_corr variables represents a
      ; different eclipse.  Loop through the list, and apply
      ; each correction to all the spin model segments overlapping
      ; that eclipse using the adjust_delta_phi method.
      
      for i=0,n_elements(fgm_corr_tend.x)-1 do begin
         tr=[fgm_corr_tend.x[i], fgm_corr_tend.y[i]]
         dp_offset=fgm_corr_offset.y[i]
         self->adjust_delta_phi,trange=tr,delta_phi_offset=dp_offset
      endfor
   endelse



   return, 1
end

pro thm_spinmodel__define
   ; Note that the probe and lastseg fields will be initialized
   ; to 0, not the values here in the prototype.  They get
   ; properly initialized in the thm_spinmodel::init method.
   ;

   self = {thm_spinmodel, probe:'a', capacity: 0L, lastseg:-1L,$
       index_n: 0L, index_t: 0L, segs_ptr: ptr_new(), $
       spincorr_times: ptr_new(), spincorr_vals: ptr_new() }
end
