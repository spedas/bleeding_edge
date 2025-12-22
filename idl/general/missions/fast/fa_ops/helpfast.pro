;+
;PROCEDURE:	helpfast
;PURPOSE:	Calls netscape and brings up our on_line help.  One of the pages
;		accessed by this on_line help provides documentation on all of
;		our procedures and is updated daily. The other is a
;		list of Data Quantity Descriptor (DQD) strings
;		recognized by SDT, for use in the SDT/IDL
;		interface. Use: 
;
;                    http://sprg.ssl.berkeley.edu/~fastsw/fastidl.html
;               
;               The links to view the source code will not work when
;               the pages are accessed in this way, unfortunately. 
; 
;
;INPUT:		none
;KEYWORDS:	
;	MOSAIC:	if set uses mosaic instead of netscape
;
;CREATED BY:	Jasper Halekas (Wind)
;STOLEN BY: Bill Peria (FAST)
; MODIFIED BY: Jon Loran (FAST also)
;FILE:   helpfast.pro
;VERSION:  1.0
;LAST MODIFICATION: @(#)helpfast.pro	1.6 10/07/99
;-
pro helpfast, mosaic = mosaic, noinstall=noinstall

if keyword_set(mosaic) then browser = 'Mosaic ' else browser = 'netscape '
if not keyword_set(noinstall) and not keyword_set(mosaic) then begin
    browser = browser + ' -install '
endif

sourcedir = 'http://sprg.ssl.berkeley.edu/~fastsw/'

spawn, browser+sourcedir+'fastidl.html &'

end
