;+
;Purpose:
; Helper routine used by thm_fitgmom_overview and thm_fitmom_overviews
; Makes a blank panel if proper data quantities are not present
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2016-10-18 15:59:42 -0700 (Tue, 18 Oct 2016) $
; $LastChangedRevision: 22140 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/blank_panel.pro $
;-
pro blank_panel,mnem,ytitle,labels=labels

dcolors = [2,4,6,0]

x = timerange(/current)

y = [!VALUES.F_NAN,!VALUES.F_NAN]

if keyword_set(labels) then begin

   
   d = {x:x,y:rebin(y,2,n_elements(labels))}

   cols = dcolors[0:(n_elements(labels)-1)]

   dl = {ytitle:ytitle,labels:labels,colors:cols,labflag:1}

endif else begin
   
   d = {x:x,y:y}

   dl = {ytitle:ytitle}

endelse

store_data,mnem,data=d,dlimits=dl

end