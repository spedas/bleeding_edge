;+
;NAME:
; thm_ui_valid_datatype
;PURPOSE:
; get valid datatype names from thm_load_* routines, using the
; valid_names keyword and returns a list of data types that can be
; loaded for each instrument.
;CALLING SEQUENCE:
; datalist = thm_ui_valid_datatype(instrument, ilist, llist)
;INPUT:
; instr_in = three letter symbol of datatype.
;OUTPUT:
; datalist = a list of the datatypes that can be loaded
; instrument = the instrument responsible for this datatype
; ilist = a list of the input instrument replicated for each datalist
;         element
; llist = the level of the data, some have 'l1', some have 'l2' some
;         have one for each
;HISTORY:
; 16-jan-2007, jmm, jimm@ssl.berkeley.edu
; 29-jan-2007, jmm, various changes, now station isn't returned, gmag
; and asi output are hard-wired, other changes will ensue when load
; routines are standardized.
; 4-feb-2007, jmm, Rewritten back to the old hard-wired version....
; 5-jul-2007, jmm, Added level information
; 11-apr-2008, jmm, now calls thm_data2load.pro, for 1 instrument
; 16-sep-2008, bck, modified from thm_ui_valid_dtype
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-09 14:43:23 -0700 (Thu, 09 Apr 2015) $
;$LastChangedRevision: 17275 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spedas_plugin/load_data/thm_ui_valid_datatype.pro $
;-
Function thm_ui_valid_datatype, instr_in, ilist, llist

  Compile_Opt idl2, hidden

  dlist = '' & ilist = '' & llist = ''
  dtyp0 = strlowcase(strcompress(instr_in, /remove))
;    l10_names = thm_data2load(dtyp0[j], 'l10') ;may need this in the future,
;    should we want raw data to be loaded in the GUI
  l1_names = thm_data2load(dtyp0, 'l1')
  If(is_string(l1_names)) Then Begin
    dlist = [dlist, l1_names]
    ilist = [ilist, replicate(dtyp0, n_elements(l1_names))]
    llist = [llist, replicate('l1', n_elements(l1_names))]
  Endif 
  l2_names = thm_data2load(dtyp0, 'l2')
  If(is_string(l2_names)) Then Begin
    dlist = [dlist, l2_names]
    ilist = [ilist, replicate(dtyp0, n_elements(l2_names))]
    llist = [llist, replicate('l2', n_elements(l2_names))]
  Endif 
  If(n_elements(dlist) Gt 1) Then Begin
    dlist = dlist[1:*]
    ilist = ilist[1:*]
    llist = llist[1:*]
  Endif
  Return, dlist
End
