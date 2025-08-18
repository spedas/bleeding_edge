
;+
;Procedure:
;  thm_pgs_clean_cmb
;
;
;Purpose:
;  Sanitize combined particle data structures for use with
;  thm_part_products.  Excess fields will be removed and 
;  field names conformed to standard.  
;
;
;Input:
;  data: Single combined particle data structure.
;  units: String specifying a units type ('flux', 'eflux', or 'df')
;
;
;Output:
;  output: Sanitized output structure for use within thm_part_products.
;
;
;Notes:
;  -not much should be happening here since the combined structures 
;   are already fairly pruned   
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-01-10 18:02:25 -0800 (Fri, 10 Jan 2014) $
;$LastChangedRevision: 13850 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_pgs_clean_cmb.pro $
;
;-
pro thm_pgs_clean_cmb, data, units, output=output, _extra=ex

  compile_opt idl2,hidden
  
  
  ;convert to requested units
  udata = conv_units(data,units,_extra=ex)
  
  output = temporary(udata)

end