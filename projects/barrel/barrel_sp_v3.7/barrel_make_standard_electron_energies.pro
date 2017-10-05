function barrel_make_standard_electron_energies,slow=slow
   e0 = barrel_make_standard_energies(slow=slow)
   if keyword_set(slow) then e=e0 else begin
      e = fltarr( (n_elements(e0)-1)*3 + 1 + 40 )
      for i=0, n_elements(e0)-2 do $
         e[3*i : 3*i + 2] = e0[i]+(e0[i+1]-e0[i])*findgen(3)/3. 
      e[3*i] = e0[i]
      for j=1,40 do e[3*i+j] = e[3*i] + j*100.
   endelse
   return,e
end
