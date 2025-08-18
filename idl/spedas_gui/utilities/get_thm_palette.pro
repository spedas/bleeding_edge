 ;+ 
;NAME: 
; get_thm_palette
;
;PURPOSE:  
; returns an IDLgrPalette object that has emulates spedas colors, so the settings
; can be properly read out of dlimits. 
; 
;CALLING SEQUENCE:
; palette = get_thm_palette()
;
;HISTORY:
;
;NOTES:
;  This does two things #1 It reads the default color table used by spedas,
;                       #2 It modifies the color table in the same way as loadct2
;  Without:             #3 Modifying the current direct graphics color table 
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/get_thm_palette.pro $
;-----------------------------------------------------------------------------------

function get_thm_palette
  
    compile_opt idl2,hidden
  
   thmctpath,getpath=thm_ct_path
   palette = obj_new('IDLgrPalette')
   palette->loadCt,43,file=thm_ct_path
   palette->getProperty,red_values=r,green_values=g,blue_values=b
   
   nc = 256
   high = 255
   low = 7
   
   ;following 3-lines from idl routine stretch.pro
   slope = float(nc-1)/(high-low)  ;Scale to range of 0 : nc-1
   intercept = -slope*low
   p = long(findgen(nc)*slope+intercept) ;subscripts to select
   
   r = r[p]
   g = g[p]
   b = b[p]

   color_idx = [indgen(7),255]

   r[color_idx] = [0,1,0,0,0,1,1,1]*255b
   g[color_idx] = [0,0,0,1,1,1,0,1]*255b
   b[color_idx] = [0,1,1,1,0,0,0,1]*255b
   
   palette->setProperty,red_values=r,green_values=g,blue_values=b
   
   return,palette
end
