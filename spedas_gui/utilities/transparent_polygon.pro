;------------------------------------------------------------------
PRO Transparent_Polygon

   ; Create some data.
   signal = LoadData(1)
   time = Findgen(N_Elements(signal)) * 6.0 / N_Elements(signal)

   ; Create some windows.
   Window, Title='Data Window', XSIZE=400, YSIZE=400, /FREE
   dataWin = !D.Window
   Window, XSIZE=400, YSIZE=400, /FREE, /PIXMAP
   pixmapWin = !D.Window

   ; Draw plot in data window.
   WSet, dataWin
   Plot, time, signal, BACKGROUND=FSC_Color('ivory'), $
      COLOR=FSC_Color('navy'), $
      /NODATA, XTitle='Time', YTitle='Signal Strength'
   OPLOT, time, signal, THICK=2, COLOR=FSC_Color('cornflower blue')
   OPLOT, time, signal, PSYM=2, COLOR=FSC_Color('olive')

   ; Take a snapshot.
   win1 = TVREAD(TRUE=3)

   ; Copy data window and draw a polygon in the pixmap window.
   WSet, pixmapWin
   DEVICE, COPY=[0,0,400, 400, 0, 0, dataWin]
   POLYFILL, [0.3, 0.65, 0.5, 0.25, 0.30], $
             [0.27, 0.32, 0.75, 0.62, 0.27], /NORMAL, $
             COLOR=FSC_COLOR('deep pink')

   ; Take a snapshot of this window, then delete it.
   win2 = TVREAD(TRUE=3)
   WDelete, pixmapWin

   ; Use a half-transparent alpha.
   alpha = 0.5
   Window, Title='Transparent Window', XSIZE=400, YSIZE=400, /FREE
   TV, (win2 * alpha) + (1 - alpha) * win1, TRUE=3

END
;------------------------------------------------------------------ 
