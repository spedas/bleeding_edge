;+
;
;Procedure:	clear_esa_common_blocks
;
;Purpose:	Clears common blocks used in esa_pkt routines, to
;               avoid using old data to create plots or L2 files
; jmm, jimm@ssl.berkeley.edu, 12-dec-2007
; $LastChangedBy: pcruce $
; $LastChangedDate: 2012-02-07 13:47:46 -0800 (Tue, 07 Feb 2012) $
; $LastChangedRevision: 9692 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/clear_esa_common_blocks.pro $

;-

Pro clear_esa_common_blocks

;clear Esa packet common blocks
  common tha_454, tha_454_ind, tha_454_dat & tha_454_dat = 0 & tha_454_ind = -1l
  common tha_455, tha_455_ind, tha_455_dat & tha_455_dat = 0 & tha_455_ind = -1l
  common tha_456, tha_456_ind, tha_456_dat & tha_456_dat = 0 & tha_456_ind = -1l
  common tha_457, tha_457_ind, tha_457_dat & tha_457_dat = 0 & tha_457_ind = -1l
  common tha_458, tha_458_ind, tha_458_dat & tha_458_dat = 0 & tha_458_ind = -1l
  common tha_459, tha_459_ind, tha_459_dat & tha_459_dat = 0 & tha_459_ind = -1l

  common thb_454, thb_454_ind, thb_454_dat & thb_454_dat = 0 & thb_454_ind = -1l
  common thb_455, thb_455_ind, thb_455_dat & thb_455_dat = 0 & thb_455_ind = -1l
  common thb_456, thb_456_ind, thb_456_dat & thb_456_dat = 0 & thb_456_ind = -1l
  common thb_457, thb_457_ind, thb_457_dat & thb_457_dat = 0 & thb_457_ind = -1l
  common thb_458, thb_458_ind, thb_458_dat & thb_458_dat = 0 & thb_458_ind = -1l
  common thb_459, thb_459_ind, thb_459_dat & thb_459_dat = 0 & thb_459_ind = -1l

  common thc_454, thc_454_ind, thc_454_dat & thc_454_dat = 0 & thc_454_ind = -1l
  common thc_455, thc_455_ind, thc_455_dat & thc_455_dat = 0 & thc_455_ind = -1l
  common thc_456, thc_456_ind, thc_456_dat & thc_456_dat = 0 & thc_456_ind = -1l
  common thc_457, thc_457_ind, thc_457_dat & thc_457_dat = 0 & thc_457_ind = -1l
  common thc_458, thc_458_ind, thc_458_dat & thc_458_dat = 0 & thc_458_ind = -1l
  common thc_459, thc_459_ind, thc_459_dat & thc_459_dat = 0 & thc_459_ind = -1l

  common thd_454, thd_454_ind, thd_454_dat & thd_454_dat = 0 & thd_454_ind = -1l
  common thd_455, thd_455_ind, thd_455_dat & thd_455_dat = 0 & thd_455_ind = -1l
  common thd_456, thd_456_ind, thd_456_dat & thd_456_dat = 0 & thd_456_ind = -1l
  common thd_457, thd_457_ind, thd_457_dat & thd_457_dat = 0 & thd_457_ind = -1l
  common thd_458, thd_458_ind, thd_458_dat & thd_458_dat = 0 & thd_458_ind = -1l
  common thd_459, thd_459_ind, thd_459_dat & thd_459_dat = 0 & thd_459_ind = -1l

  common the_454, the_454_ind, the_454_dat & the_454_dat = 0 & the_454_ind = -1l
  common the_455, the_455_ind, the_455_dat & the_455_dat = 0 & the_455_ind = -1l
  common the_456, the_456_ind, the_456_dat & the_456_dat = 0 & the_456_ind = -1l
  common the_457, the_457_ind, the_457_dat & the_457_dat = 0 & the_457_ind = -1l
  common the_458, the_458_ind, the_458_dat & the_458_dat = 0 & the_458_ind = -1l
  common the_459, the_459_ind, the_459_dat & the_459_dat = 0 & the_459_ind = -1l

  Return
End
