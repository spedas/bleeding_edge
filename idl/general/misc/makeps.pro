;+
;NAME:
; makeps.pro
;PURPOSE:
;
;OBSOLETE: please use tprint or popen and pclose
; A simple function to reliably and consistently do postscript export
; Right now it will export whatever your last tplot command was(ie
; current plot)
;CALLING SEQUENCE:
; makeps
; -or-
; makeps,'filename'
;INPUT:
; a filename or nothing
;OUTPUT:
; a postscript file to the specified location
; errors, grays out all buttons while processing
;
;NOTES: Will append a .ps to your filename whether you like it or not
;       TODO: add an argument to accept a list of variables
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2008-04-14 15:50:24 -0700 (Mon, 14 Apr 2008) $
;$LastChangedRevision: 2719 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/makeps.pro $
;
;-
pro makeps,filename


message,/continue,'Make ps is obsolete.  Please use the alternative functions in our distribution:tprint, or popen and pclose'

;if(not keyword_set(filename)) then filename = 'tplotpostscript'

;mydevice = !D.NAME  

;myplot = !p 

;SET_PLOT, 'PS' 

;DEVICE, FILENAME=filename+'.ps',/color,bits_per_pixel=8

;tplot

;DEVICE, /CLOSE  

;SET_PLOT, mydevice  

;!p = myplot

end
