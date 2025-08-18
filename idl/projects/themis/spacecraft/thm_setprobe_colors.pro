;+
;  Procedure thm_setprobe_colors [,tplotnames]
;    Only scalar tplot variables will be changed.
;
;  Keywords:
;     tplotnames: the names of the variables you want modified
;                 (accepts wildcards)
;
;     default(optional): set to modify dlimits rather than limits
;
;     tplotxy(optional): set to modify colors for use with tplotxy rather
;                        than tplot
;
;  Author: Davin Larson(davin@ssl.berkeley.edu)
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2008-01-16 16:54:40 -0800 (Wed, 16 Jan 2008) $
; $LastChangedRevision: 2283 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/ssl_general/trunk/tplot/tplotxy.pro $
;-
pro thm_setprobe_colors,tplotnames,default=default,tplotxy=tplotxy

if not keyword_set(tplotnames) then tplotnames='th[abcde]_*'
tn = tnames(tplotnames,n)

;probe_colors=['m','b','c','g','r','y']   ; Davin's preference
probe_colors=['m','r','g','c','b','y']   ; Standard color choices

probe_letter = strmid(tn,2,1)
pn = byte(probe_letter) - (byte('a'))[0]
for i=0,n-1 do begin
   get_data,tn[i],ptr=ptr
   if not keyword_set(ptr) then continue

   if keyword_set(tplotxy) then $
      options,def=default,tn[i],colorsxy = probe_colors[pn[i]] $
   else $
      if size(/n_dimen,*ptr.y) eq 1 then $
         options,def=default,tn[i],colors = probe_colors[pn[i]] $
      else $
         dprint,dlevel=2,'Using multi dimensional data no action is being taken'

endfor

end

