;+
; NAME:
;    THM_AUTOLOAD_SPINMODEL.PRO
;
; PURPOSE:
;    Given a tplot variable name, or an explicit time range,
;    check to see whether a spin model is loaded. If not, or
;    if the time range of interest is not completely covered,
;    call thm_load_state to load the spin model and support data.
;
; CATEGORY:
;   TDAS
;
; CALLING SEQUENCE:
;   thm_autoload_spinmodel,probe='a',tvar='tha_mom'
;
;  INPUTS:
;    probe: A scalar character, one of 'a' through 'f', specifying which
;       probe's spinmodel to check.
;
;    tvar: A tplot variable name, defining the time range of interest.
;
;    trange: A double precision two element array, defining the time range
;            of interest.
;
;    One of tvar or trange must be specified.
;
;  OUTPUTS:
;     Support data and a spin model are loaded, if necessary.
;

pro thm_autoload_spinmodel,tvar=tvar,trange=trange,probe=probe

   need_load=0

   if keyword_set(tvar) then begin
     get_data,tvar,data=d
     roi=minmax(d.x)
   endif else begin
      if keyword_set(trange) then begin
        roi=trange
      endif else begin
        message,'One of tvar or trange keywords must be set to establish the region of interest.'
      endelse
   endelse

   smp=spinmodel_get_ptr(probe)
   if ~obj_valid(smp) then begin
      need_load=1
      t1=0.0D
      t2=0.0D
   endif else begin
      smp->get_info,start_time=t1, end_time=t2
      if (roi[0] LE t1) OR (roi[1] GE t2) then begin
         need_load=1
      endif
   endelse

   if (need_load NE 0) then begin
      ;print,'ROI: '+time_string(roi[0])+' to '+time_string(roi[1])
      ;print,'Loaded: '+time_string(t1) + ' to '+time_string(t2)
      ;dprint,'Spin model coverage does not match ROI, loading state support data.'
      thm_load_state,probe=probe,trange=roi,/get_supp
   endif else begin
      ;dprint,'Spin model covers entire ROI, no load needed.'
   endelse
end
