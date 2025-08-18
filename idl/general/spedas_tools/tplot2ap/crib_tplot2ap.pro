;+
; PROCEDURE:
;         crib_tplot2ap
;
; PURPOSE:
;         Crib sheet showing how to send data to Autoplot
;
; NOTES:
;         For this to work, you'll need to open Autoplot and enable the 'Server' feature via
;         the 'Options' menu with the default port (12345)
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-01-12 08:46:29 -0800 (Fri, 12 Jan 2018) $
; $LastChangedRevision: 24514 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/tplot2ap/crib_tplot2ap.pro $
;-

kyoto_load_dst, trange=['2015-12-15', '2015-12-16']

tplot2ap, 'kyoto_dst'

stop
end