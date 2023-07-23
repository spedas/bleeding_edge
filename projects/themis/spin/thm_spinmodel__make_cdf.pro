;+
; NAME:
;    THM_SPINMODEL::MAKE_CDF.PRO
;
; PURPOSE:
;     Export the segments data for a spinmodel as tplot variables, then write to a CDF.
;
; CATEGORY:
;   TDAS
;
; CALLING SEQUENCE:
;   smp = spinmodel_get_ptr('a',use_eclipse_corrections=2)
;
;  INPUTS:
;    prefix: A string to be prepended to segment attribute names to form tplot variables
;    cdf_filename: The filename of the CDF to be produced.
;    
;  OUTPUTS: (all optional)
;    None
;
;  
;  EXAMPLE:
;     timespan,'2007-03-23',1,/days
;     thm_load_state,probe='a',/get_support_data
;
;     smp = spinmodel_get_ptr('a',use_eclipse_corrections=2)
;     smp->make_cdf,prefix='tha_corr2_',cdf_filename='tha_corr2.cdf'
;-

pro thm_spinmodel::make_cdf,prefix=prefix,cdf_filename=cdf_filename

  self.make_tplot_vars,prefix=prefix

  tplot2cdf,filename=cdf_filename,tvars=tnames(prefix+'*'),/default_cdf_structure
   
end
