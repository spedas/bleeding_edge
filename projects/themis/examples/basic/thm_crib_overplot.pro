;+
; NAME: thm_crib_overplot
;
; PURPOSE: this crib describes how to generate overview plots
;          if there are any arguments or features for these 
;          procedures you would like to request, please feel 
;          free to ask.
;          
; SEE ALSO:
;         examples/basic/thm_crib_trace.pro (for field line traces with spacecraft position/footpoints)
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2014-11-17 12:15:34 -0800 (Mon, 17 Nov 2014) $
; $LastChangedRevision: 16199 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/basic/thm_crib_overplot.pro $
;-

;-------------------------------------------------------------------------
;To get the single-spacecraft overview plot
;-------------------------------------------------------------------------

thm_gen_overplot, probe='d', date='2010-04-05'
stop

;-------------------------------------------------------------------------
;set the /makepng keyword  to get output files, this will give the full
;day file, and the six-hour ones
;-------------------------------------------------------------------------

;to get FGM tohban plots
thm_fgm_overviews, '2010-04-05', /nopng 
stop

;-------------------------------------------------------------------------
;for the tohban plots, png files are done as a default, /nopng turns this 
;off, also for these thedate is nota keyword
;-------------------------------------------------------------------------

;ESA, SST are the same
thm_esa_overviews, '2010-04-05', /nopng
thm_sst_overviews, '2010-04-05', /nopng
stop


;for the esa you get burst, reduced and full plots, for sst you get
;full and reduced plots.
;
;-------------------------------------------------------------------------
;for the new memory plots, the date is a keyword input. (these really 
;should be consistent..)
;-------------------------------------------------------------------------
thm_memory_plots, date = '2010-04-05', /nopng
stop

;-------------------------------------------------------------------------
;here is an example of how to create a moment overview plot
;this plot uses on-board moments whenever possible
;-------------------------------------------------------------------------

thm_fitmom_overviews,'2010-04-05','d'
stop


;to make png's
;thm_fitmom_overviews,'2007-11-15','b',/makepng
;
;-------------------------------------------------------------------------
;here is an example of how to create another moment overview plot
;this plot always uses ground processed moments
;-------------------------------------------------------------------------

thm_fitgmom_overviews,'2010-04-05','d'
stop

;to make png's
;thm_fitmom_overviews,'2007-11-15','b',/makepng

End
