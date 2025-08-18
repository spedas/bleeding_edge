;+
; NAME:
;    VH (short for ViewHelp)
;
; PURPOSE:
;     Make a shortcut to the IDL procedure DOC_LIBRARY
;
; CALLING SEQUENCE
;     vh, pro_name
; 
; ARGUMENTS:
;     pro_name: (INPUT, REQUIRED) The name of the routine whose help document is
;         to be shown. It could be a string. For example, the following IDL
;         command shows the help info of the routine TPLOT.
;                   vh, 'tplot'
;         It could also simply be the name of the routine (without the quotes),
;         if no variable with the same name as the routine is defined. For
;         example, if no variable is named TPLOT, the following command command
;         does the same thing as the one above.
;                   vh, tplot
;
; HISTORY:
;   2008-05-23: Created by Jianbao Tao (JBT), CU/LASP
;   2010-12-12: JBT, CU/LASP.
;       1. The help document was improved.
;   2012-07-20: JBT, SSL, UC Berkeley.
;       1. Added the VERSION to the documentation comment.
;
; VERSION:
;   $LastChangedBy: jianbao_tao $
;   $LastChangedDate: 2012-07-23 17:44:33 -0700 (Mon, 23 Jul 2012) $
;   $LastChangedRevision: 10737 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/LASP/vh.pro $
;-

pro vh, pro_name
  if n_elements(pro_name) eq 0 then begin
    name = scope_varname(pro_name, level = -1)
  endif else begin
    name = pro_name
  endelse

  doc_library, name
end




