;+
; NAME:
;    SPINMODEL_TEST.PRO
;
; PURPOSE:
;   Perform consistency checks on a spin model.
;
; CATEGORY:
;   TDAS
;
; CALLING SEQUENCE:
;   spinmodel_test,model_ptr
;
;  INPUTS:
;    model_ptr: A pointer to a spinmodel structure, obtained from the 
;    spinmodel_common block or the spinmodel_get_ptr() function.
;    This input must be a scalar.
;
;  OUTPUTS:
;    Prints "PASS"/"FAIL" messages depending on outcome of tests.
;
;  KEYWORDS:
;    None.
;
;  PROCEDURE:
;    Validate model_ptr input argument.
;    Compare spin model capacity to actual number of segments.
;    Validate pointer to model segments.
;    Call segment_test on each model segment, check for any failures.
;    Examine boundaries of adjacent segments, making sure time and
;       spin_number endpoints are identical across each pair.
;    Exercise spinmodel_interp_n by retrieving modeled sun pulse
;       times by spin number.
;    Exercise spinmodel_interp_t by recalculating the spin count
;       and spin phase at each modeled sun pulse time.
;    Cross check results of spinmodel_interp_n and spinmodel_interp_t
;       to verify that the expected values are produced within
;       modest tolerances (allowable phase error .01 deg at each
;       modeled sun pulse time).
;
;    
;
;  EXAMPLE:
;     model_ptr=spinmodel_get_ptr('a')
;     spinmodel_test,model_ptr
;
;Written by: Jim Lewis (jwl@ssl.berkeley.edu)
;Change Date: 2007-10-08
;-

pro spinmodel_test,mptr

if (ptr_valid(mptr) EQ 0) then begin
  dprint,'FAIL: Model pointer invalid.'
  message,'Bad spin model pointer.'
  return
endif

if ((*mptr).capacity LE 0) then begin
  dprint,'FAIL: Model ',(*mptr).probe,' contains no segments.'
  message,'Empty spin model.'
  return
endif

lastseg = (*mptr).lastseg
if ((lastseg LT 0) OR (lastseg GE (*mptr).capacity)) then begin
  dprint,'FAIL: Model ',(*mptr).probe,' lastseg=',lastseg,' but capacity=',(*mptr).capacity  
  message,'Spin model lastseg index is corrupt.'
  return
end

index_n = (*mptr).index_n
if ((index_n LT 0) OR (index_n GE (*mptr).capacity)) then begin
  dprint,'FAIL: Model ',(*mptr).probe,' index_n=',index_n,' but capacity=',(*mptr).capacity  
  message,'Spin model index_n is corrupt.'
  return
end

index_t = (*mptr).index_t
if ((index_t LT 0) OR (index_t GE (*mptr).capacity)) then begin
  dprint,'FAIL: Model ',(*mptr).probe,' index_t=',index_t,' but capacity=',(*mptr).capacity  
  return
end

sp = (*mptr).segs_ptr

if (ptr_valid(sp) EQ 0) then begin
  dprint,'FAIL: Model ',(*mptr).probe,' segs_ptr not a valid pointer.'
  message,'Spin model index_t is corrupt.'
  return
end


for i=0L,lastseg,1L do begin
  segment_test,(*mptr).probe,(*sp)[i],result
  if (result NE 1) then begin
     dprint,'FAIL: Model ',(*mptr).probe,' contains bad segment at index ',i
     return
  endif else if (i GT 0) then begin
     tgap=(*sp)[i].t1 - (*sp)[i-1].t2
     ngap = (*sp)[i].c1 - (*sp)[i-1].c2
     if ( (ngap NE 0L) OR (abs(tgap) GT 0.0D)) then begin
        dprint,'FAIL: Model ',(*mptr).probe,' contains discontinuity at index ',i,' :'
        print_segment,(*sp)[i-1]
        print_segment,(*sp)[i]
        message,'Spin model contains discontinuity at segment boundary.'
        return
     end
  endif
endfor

t1=(*sp)[0].t1
c1=0L
t2=(*sp)[lastseg].t2
c2=(*sp)[lastseg].c2

spinnums=lindgen(c2+1)
spinmodel_interp_n,model=mptr,count=spinnums,time=spintimes

; For self-test purposes: disable the spinphase corrections from
; V03 state.  Otherwise there will be a discrepancy between
; the results of spinmodel_interp_n and spinmodel_interp_t
; for times with nonzero corrections.

spinmodel_interp_t,model=mptr,time=spintimes,spinphase=spinphase,spincount=spincount,use_spinphase_correction=0
phi_expect=360.0D*spinnums
phi_obs=360.0D*spincount+spinphase
phi_diff=phi_obs-phi_expect
max_abs_diff=max(phi_diff,index,/absolute)
if (abs(max_abs_diff) GT 0.01) then begin
   dprint,'FAIL: model ',(*mptr).probe,' has phase mismatch of ',max_abs_diff,' deg at spincount=',spinnums[index],' (max acceptable value 0.01 deg)'
   dprint,'Expected phi=',phi_expect[index],', got phi=',phi_obs[index]
   message,'Spin model contains spin phase mismatch.'
   return
end


print,'PASS: Model ',(*mptr).probe,' passes all internal consistency checks.'
end
