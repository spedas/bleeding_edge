;+
; Function: spinmodel_post_process
; 
; Purpose: Performs post-load corrections on spinmodel data.
;          
; Notes: Somewhat finicky about data requirements.  Will throw an error that
;  causes interpreter to halt unless the error is explicitly caught.  Error's
;  will be returned in the SPINMODEL_POST_PROCESS message block.
;  
;  If you find execution halted here and you aren't sure why, it is probably
;  because the state support data was not loaded. 
;  This occurs most commonly because
;  1. there is no data available on this day, or
;  2. because of internet connection issues,
;  3. because the !themis.no_download flag is on. 
;               
;   
; 
; 
; $LastChangedBy: bsadeghi $
; $LastChangedDate: 2012-05-22 10:48:29 -0700 (Tue, 22 May 2012) $
; $LastChangedRevision: 10447 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spin/spinmodel_post_process.pro $
;- 

pro spinmodel_post_process,sname=sname,filetype=filetype,datatype=datatype,$
  suffix=suffix,coord=coord,level=level,verbose=verbose,$
  progobj=progobj,midfix=midfix,_extra=_extra

common spinmodel_common, tha_std_obj, thb_std_obj, thc_std_obj,$
                        thd_std_obj, the_std_obj, thf_std_obj,$
                        tha_ecl_obj, thb_ecl_obj, thc_ecl_obj,$
                        thd_ecl_obj, the_ecl_obj, thf_ecl_obj,$
                        tha_full_obj, thb_full_obj, thc_full_obj,$
                        thd_full_obj, the_full_obj, thf_full_obj, init_flag

; define message block
ename = ['INVAL_PROBE', 'NO_TVAR', 'ZERO_SPINPER', 'OBJ_INVALID']
efmt = ['Unrecognized sname value: %s', $
       'spinmodel_post_process: tplot variable not found: %s, This indicates that State Support Data is unavailable, unloaded, or incorrect.', $
       'spinper[0] = 0 for probe %s, probably due to empty tplot variable.',$
       'The standard spinmodel object for probe %s could not be constructed, probably due to a missing tplot variable.']
DEFINE_MSGBLK, 'SPINMODEL_POST_PROCESS', PREFIX='THM_SPINMODEL_POST_PROCESS_', $
               ename, efmt, /ignore_duplicate


if n_elements(init_flag) EQ 0 then begin
   ; Initialize all spinmodel object to null pointers
   tha_std_obj=obj_new()
   thb_std_obj=obj_new()
   thc_std_obj=obj_new()
   thd_std_obj=obj_new()
   the_std_obj=obj_new()
   thf_std_obj=obj_new()

   tha_ecl_obj=obj_new()
   thb_ecl_obj=obj_new()
   thc_ecl_obj=obj_new()
   thd_ecl_obj=obj_new()
   the_ecl_obj=obj_new()
   thf_ecl_obj=obj_new()

   tha_full_obj=obj_new()
   thb_full_obj=obj_new()
   thc_full_obj=obj_new()
   thd_full_obj=obj_new()
   the_full_obj=obj_new()
   thf_full_obj=obj_new()
endif

; Set the initialization flag, indicating that it's safe to use 
; all the variables in the common block (even if they happen
; to be initialized to null pointers or object references).

init_flag=1

; Make spinmodel objects

; Standard model
dprint,'Constructing standard spinmodel object for probe ' + sname + '.'
std_obj = obj_new('thm_spinmodel',probe=sname,midfix=midfix,suffix=suffix,eclipse=0)

if ~obj_valid(std_obj) then begin
  message, name='thm_spinmodel_post_process_obj_invalid', block='spinmodel_post_process', $
           sname
endif

; Partially corrected eclipse model
; If an eclipse model cannot be constructed (maybe old state CDFs without
; the new eclipse spin model variables), it is not a fatal error.
dprint,'Constructing partially corrected eclipse spinmodel object for probe ' + sname + '.'
ecl_obj = obj_new('thm_spinmodel',probe=sname,midfix=midfix,suffix=suffix,eclipse=1)

if ~obj_valid(ecl_obj) then begin
   dprint, 'An eclipse spin model could not be produced for probe '+sname+ '.  This is a non-fatal error...the standard spin model will be used instead.'

   ; Setting ecl_obj=std_obj might be tempting here, but then we'd have
   ; two references to the same object, and we could end up double-freeing it.
   ; So we make an identical, but distinct, object, from scratch, with the
   ; eclipse flag disabled.

   ecl_obj = obj_new('thm_spinmodel',probe=sname,midfix=midfix,suffix=suffix,eclipse=0)
endif

; Fully corrected eclipse model
; If an eclipse model cannot be constructed (maybe old state CDFs without
; the new eclipse spin model variables), it is not a fatal error.
dprint,'Constructing fully corrected eclipse spinmodel object for probe ' + sname + '.'
full_obj = obj_new('thm_spinmodel',probe=sname,midfix=midfix,suffix=suffix,eclipse=2)

if ~obj_valid(full_obj) then begin
   dprint, 'A fully corrected eclipse spin model could not be produced for probe '+sname+ '.  This is a non-fatal error...falling back to partial or standard model.'

   full_obj = obj_new('thm_spinmodel',probe=sname,midfix=midfix,suffix=suffix,eclipse=1)
   if ~obj_valid(full_obj) then begin
       full_obj = obj_new('thm_spinmodel',probe=sname,midfix=midfix,suffix=suffix,eclipse=0)
   endif
endif


case sname of
'a': begin
       obj_destroy,tha_std_obj
       tha_std_obj=std_obj
       obj_destroy,tha_ecl_obj
       tha_ecl_obj=ecl_obj
       obj_destroy,tha_full_obj
       tha_full_obj=full_obj
     end
'b': begin
       obj_destroy,thb_std_obj
       thb_std_obj=std_obj
       obj_destroy,thb_ecl_obj
       thb_ecl_obj=ecl_obj
       obj_destroy,thb_full_obj
       thb_full_obj=full_obj
     end
'c': begin
       obj_destroy,thc_std_obj
       thc_std_obj=std_obj
       obj_destroy,thc_ecl_obj
       thc_ecl_obj=ecl_obj
       obj_destroy,thc_full_obj
       thc_full_obj=full_obj
     end
'd': begin
       obj_destroy,thd_std_obj
       thd_std_obj=std_obj
       obj_destroy,thd_ecl_obj
       thd_ecl_obj=ecl_obj
       obj_destroy,thd_full_obj
       thd_full_obj=full_obj
     end
'e': begin
       obj_destroy,the_std_obj
       the_std_obj=std_obj
       obj_destroy,the_ecl_obj
       the_ecl_obj=ecl_obj
       obj_destroy,the_full_obj
       the_full_obj=full_obj
     end
'f': begin
       obj_destroy,thf_std_obj
       thf_std_obj=std_obj
       obj_destroy,thf_ecl_obj
       thf_ecl_obj=ecl_obj
       obj_destroy,thf_full_obj
       thf_full_obj=full_obj
     end
endcase
end
