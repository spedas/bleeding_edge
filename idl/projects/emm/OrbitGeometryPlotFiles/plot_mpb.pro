pro plot_mpb, linecolor=linecolor, $
              linethick=linethick, $
	      linestyle=linestyle, $
	      allangles=allangles, $
              trotignon=trotignon
;;;;;;;;;;
; assumes plot window set, and is in units of Rm
; Dave Brain
; Feb 15 2005
;;;;;;;;;;;;

   IF n_elements(linecolor) EQ 0 THEN linecolor = !p.color
   IF n_elements(linethick) EQ 0 THEN linethick = 1
   IF n_elements(linestyle) EQ 0 THEN linestyle = 0

   angles = findgen(161)*!DTOR
   
   if keyword_set(trotignon) then begin

      ; Draw Trotignon mpb 
         eccen = 0.77                                 ; Eccentricity
         L     = 1.08                                 ; L-distance for mpb
         X0    = 0.64                                 ; Focus
         shockr     = L / ( 1. + eccen *  $           ; find dist to focus
                      cos(angles) )
         shockx     = X0 + shockr *  cos(angles)      ; calculate x
         shockmsd   = shockr * sin(angles)         ; calc dist to Mars-Sun li
         
         eccen = 1.009                                 ; Eccentricity
         L     = 0.528                                 ; L-distance for mpb
         X0    = 1.6                                   ; Focus
         shockr2     = L / ( 1. + eccen *  $           ; find dist to focus
                      cos(angles) )
         shockx2     = X0 + shockr2 *  cos(angles)      ; calculate x
         shockmsd2   = shockr2 * sin(angles)         ; calc dist to Mars-Sun li
         
         nite = where(shockx2 lt 0)
         day = where(shockx gt 0)
         shockx = [ shockx[day], shockx2[nite] ]
         shockmsd = [ shockmsd[day], shockmsd2[nite] ]
         
         oplot, shockx, shockmsd, $   
   	    thick = linethick, $
   	    color=linecolor, $
   	    linestyle=linestyle

      IF n_elements(allangles) NE 0 THEN BEGIN
      
      angles = -1.*findgen(161)*!DTOR
         
      ; Draw Trotignon mpb 
         eccen = 0.77                                 ; Eccentricity
         L     = 1.08                                 ; L-distance for mpb
         X0    = 0.64                                 ; Focus
         shockr     = L / ( 1. + eccen *  $           ; find dist to focus
                      cos(angles) )
         shockx     = X0 + shockr *  cos(angles)      ; calculate x
         shockmsd   = shockr * sin(angles)         ; calc dist to Mars-Sun li
         
         eccen = 1.009                                 ; Eccentricity
         L     = 0.528                                 ; L-distance for mpb
         X0    = 1.6                                   ; Focus
         shockr2     = L / ( 1. + eccen *  $           ; find dist to focus
                      cos(angles) )
         shockx2     = X0 + shockr2 *  cos(angles)      ; calculate x
         shockmsd2   = shockr2 * sin(angles)         ; calc dist to Mars-Sun li
         
         nite = where(shockx2 lt 0)
         day = where(shockx gt 0)
         shockx = [ shockx[day], shockx2[nite] ]
         shockmsd = [ shockmsd[day], shockmsd2[nite] ]
         
         oplot, shockx, shockmsd, $   
   	    thick = linethick, $
   	    color=linecolor, $
   	    linestyle=linestyle
   
      ENDIF

   endif else begin
      
      ; Draw Vignes mpb 
         eccen = 0.90                                 ; Eccentricity
         L     = 0.96                                 ; L-distance for mpb
         X0    = 0.78                                 ; Focus
         shockr     = L / ( 1. + eccen *  $           ; find dist to focus
                      cos(angles) )
         shockx     = X0 + shockr *  cos(angles)      ; calculate x
         shockmsd   = shockr * sin(angles)         ; calc dist to Mars-Sun li
         
         oplot, shockx, shockmsd, $   
   	    thick = linethick, $
   	    color=linecolor, $
   	    linestyle=linestyle
   
      IF n_elements(allangles) NE 0 THEN BEGIN
      
      angles = -1.*findgen(161)*!DTOR
         
      ; Draw Vignes mpb 
         eccen = 0.90                                 ; Eccentricity
         L     = 0.96                                 ; L-distance for mpb
         X0    = 0.78                                 ; Focus
         shockr     = L / ( 1. + eccen *  $           ; find dist to focus
                      cos(angles) )
         shockx     = X0 + shockr *  cos(angles)      ; calculate x
         shockmsd   = shockr * sin(angles)         ; calc dist to Mars-Sun li
         
         oplot, shockx, shockmsd, $   
   	    thick = linethick, $
   	    color=linecolor, $
   	    linestyle=linestyle
   
      ENDIF

   endelse
      
end
