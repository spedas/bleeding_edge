;+
; PRO: das2dlm_add_metadata, ...
;
; Description:
;    Adds following metadata from das2dlm outputs into a structure
;    'name' - name of the variable 
;    'use' - how it should be used
;    'units' - units
;    'props' -  structure of das2dlm properties
;
; Keywords:
;    DAS2: Structure where metadata will be added
;    p: Physical dimension, das2c_pdims
;    v: Variable, das2c_vars
;    m: Properties, das2c_props
;    add (optional): adds postfix to the metadata field (default: '')
;
; CREATED BY:
;    Alexander Drozdov (adrozdov@ucla.edu)
;
; NOTE:
;   This function is under active development. Its behavior can change in the future.
;
; $LastChangedBy: adrozdov $
; $Date: 2020-08-03 20:45:11 -0700 (Mon, 03 Aug 2020) $
; $Revision: 28983 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/das2dlm/das2dlm_add_metadata.pro $
;-

pro das2dlm_add_metadata, DAS2, p=p, v=v, m=m, add=postfix

  if undefined(postfix) $  
  then postfix = ''
  

  ; TODO: check validity of the fields

  str_element, DAS2, 'name' + postfix, p.pdim, /add  
  str_element, DAS2, 'use' + postfix, p.use, /add    
  str_element, DAS2, 'units' + postfix, v.units, /add  
  str_element, DAS2, 'props' + postfix, m, /add

end