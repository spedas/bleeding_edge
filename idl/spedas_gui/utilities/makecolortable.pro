;+
;
;NAME: makecolortable
;
;PURPOSE:
;  makes the color table file for the spedas gui 
;
;CALLING SEQUENCE:
;   makecolortable
;
;EFFECTS:
;  overwrites the file spedas/spd_ui/utilities/spd_gui_colors.tbl
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2016-10-18 16:31:28 -0700 (Tue, 18 Oct 2016) $
;$LastChangedRevision: 22141 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/makecolortable.pro $
;----------


pro makeColortable

  getctpath,ctfile
  
  ;rainbow
  
;  loadct,13
;  
;  tvlct,r,g,b,/get

  rtt = interpol([0  ,0  ,0  ,255,255,128],256)
  gtt = interpol([0  ,0  ,255,255,0  ,0  ],256)
  btt = interpol([128,255,255,0  ,0  ,0  ],256)
  
  modifyct,0,"Rainbow",rtt,gtt,btt,file=ctfile
  
  ;cool
  
  rtt = interpol([0,255],256)
  gtt = interpol([255,0],256)
  btt = interpol([255,255],256)
  
  modifyct,1,"Cool",rtt,gtt,btt,file=ctfile
  
  ;Hot
  
  rtt = interpol([0,255,255,255],256)
  gtt = interpol([0,0,255,255],256)
  btt = interpol([0,0,0,255],256)

  modifyct,2,'Hot',rtt,gtt,btt,file=ctfile
  
  ;Copper
  
  loadct,3,file=ctfile
  
  tvlct,r,g,b,/get
  
  rtt = interpol([0,245,r[220]],256)
  gtt = interpol([0,143,g[220]],256)
  btt = interpol([0,101,b[220]],256)
 
  a = [.65*(dindgen(128)/127D),.65+(dindgen(128)/127D)*.35]
  b = [.35*(dindgen(128)/127D),.35+(dindgen(128)/127D)*.65]
  
  rtt = interpol(rtt,a,b)
  gtt = interpol(gtt,a,b)
  btt = interpol(btt,a,b)

;  rtt = interpol([0,184,218,244],256)
;  gtt = interpol([0,115,138,164],256)
;  btt = interpol([0,81,103,96],256)

  modifyct,3,"Copper",rtt,gtt,btt,file=ctfile
  
  ;Extreme Hot-Cold
 
  rtt = reverse(interpol([255,255,255,0,128,0,0],256))
  gtt = reverse(interpol([255,255,0,0,128,0,255],256))
  btt = reverse(interpol([255,0,0,0,255,255,255],256))
  
  modifyct,4,"Extreme Hot-Cold",rtt,gtt,btt,file=ctfile
  
  ;Grey
  loadct,0
  
  tvlct,r,g,b,/get
  
  modifyct,5,"Grey",r,g,b,file=ctfile
  
  ;SPEDAS
  ;loadct,13
  
  spedas_init
  loadct2,43
  
  tvlct,r,g,b,/get
  rtt = interpol(r[7:254],256)
  gtt = interpol(g[7:254],256)
  btt = interpol(b[7:254],256)
  
  modifyct,6,"SPEDAS",rtt,gtt,btt,file=ctfile
  
end
