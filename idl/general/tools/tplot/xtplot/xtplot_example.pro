; This is an example program to be called from 
; the "Auto Command" feature (in the "Options" menu)
;
PRO xtplot_example
@xtplot_com
  pA = xtplot_pcsrA
  pB = xtplot_pcsrB
  
  print, xtplot_pcsrA, xtplot_pcsrB
  print, xtplot_vnameA
  print, xtplot_vnameB

  if strmatch(xtplot_vnameA, xtplot_vnameB) then begin
    if (pB eq 0 ) then begin
      msg = 'Please set two cursors, because this example program calculates a sum between two cursors.'
      result = dialog_message(msg,/center)
    endif else begin
      if pB lt pA then begin
        pAtmp = pA
        pA = pB
        pB = pAtmp
      endif
    endelse
    
    get_data, xtplot_vnameA, data=D
    sz = size(D.y)
    ndim = sz[0]
    case ndim of
      1:begin; scalar
        sum = total(D.y[pA:pB])
        avg = sum/float(pB-pA+1.)
        tag = xtplot_vnameA
        end
      2:begin; vector or spectrogram
        tag = 'the '
        tag += (sz[2] eq 3) ? 'x-component': 'first element'
        tag += ' of '+xtplot_vnameA
        sum = total(D.y[pA:pB, 0])
        avg = sum/float(pB-pA+1.)
        end
      else:begin
        sum = !VALUES.F_NAN
        avg = !VALUEA.F_NAN
        end
    endcase
        
    print, '***************************************'
    print, 'average of '+tag+' between the two cursors are: ', avg
    print, '***************************************'
  endif
END
