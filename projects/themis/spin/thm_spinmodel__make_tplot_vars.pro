;+
; NAME:
;    THM_SPINMODEL::MAKE_TPLOT_VARS.PRO
;
; PURPOSE:
;    Export spin model segment attributes as a set of tplot variables
;
; CATEGORY:
;   TDAS
;
; CALLING SEQUENCE:
;   spinmodel->make_tplot_vars,prefix=prefix
;
;  INPUTS:
;    prefix:  A string to be prepended to each segment attribute to form tplot variable names.
;
;  OUTPUTS: 
;    None
;
;  
;  EXAMPLE:
;     timespan,'2007-03-23',1,/days
;     thm_load_state,probe='a',/get_support_data
;
;     smp = spinmodel_get_ptr('a',use_eclipse_corrections=2)
;     smp->make_tplot_vars,prefix='tha_corr2_'
;
;-

function thm_spinmodel::make_tplot_vars,prefix=prefix

  sp = self.segs_ptr

  seg_array = *sp

  seg_times=seg_array[*].t1
  seg_t2=seg_array[*].t2
  seg_c1=seg_array[*].c1
  seg_c2=seg_array[*].c2
  seg_b=seg_array[*].b
  seg_c=seg_array[*].c
  seg_npts=seg_array[*].npts
  seg_maxgap=seg_array[*].maxgap
  seg_phaserr=seg_array[*].phaserr
  seg_idpu_spinper=seg_array[*].idpu_spinper
  seg_initial_delta_phi=seg_array[*].initial_delta_phi
  seg_segflags=seg_array[*].segflags
  
  store_data,prefix+'t1',data={x:seg_times,y:seg_times}
  store_data,prefix+'t2',data={x:seg_times,y:seg_t2}
  store_data,prefix+'c1',data={x:seg_times,y:seg_c1}
  store_data,prefix+'c2',data={x:seg_times,y:seg_c2}
  store_data,prefix+'b',data={x:seg_times,y:seg_b}
  store_data,prefix+'c',data={x:seg_times,y:seg_c}
  store_data,prefix+'npts',data={x:seg_times,y:seg_npts}
  store_data,prefix+'maxgap',data={x:seg_times,y:seg_maxgap}
  store_data,prefix+'phaserr',data={x:seg_times,y:seg_phaserr}
  store_data,prefix+'idpu_spinper',data={x:seg_times,y:seg_idpu_spinper}
  store_data,prefix+'initial_delta_phi',data={x:seg_times,y:seg_initial_delta_phi}
  store_data,prefix+'segflags',data={x:seg_times,y:seg_segflags}
  
  dqlist=['t1','t2','c1','c2','b','c','npts','maxgap','phaserr','idpu_spinper','initial_delta_phi','segflags']
  return, prefix+dqlist
  
 
end
