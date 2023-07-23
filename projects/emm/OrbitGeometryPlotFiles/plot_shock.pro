pro plot_shock, linecolor=linecolor, $
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

   ; Vignes
      epsilon = 1.03
      x0 = .64
      L = 2.04
   ; Trotignon
      if keyword_set(trotignon) then begin
         epsilon = 1.026
         L = 2.081
         x0 = 0.6
      endif

   angles = findgen(161)*!DTOR
      
   ; Draw Vignes mpb 
      shockr     = L / ( 1. + epsilon *  $           ; find dist to focus
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
      shockr     = L / ( 1. + epsilon *  $           ; find dist to focus
                   cos(angles) )
      shockx     = X0 + shockr *  cos(angles)      ; calculate x
      shockmsd   = shockr * sin(angles)         ; calc dist to Mars-Sun li
      
      oplot, shockx, shockmsd, $   
	 thick = linethick, $
	 color=linecolor, $
	 linestyle=linestyle

   ENDIF


end
