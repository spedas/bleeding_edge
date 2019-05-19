;+
;FUNCTION:  rotate_data,x,rotmatrix
;INPUT:   several options exist for x:
;    string:    data associated with the string is used.
;    structure: data.y is used
;    1 dimensional array
;    2 dimensional array
;   rotmatrix:   typically a 3 by 3 rotation matrix.
;RETURN VALUE:  Same dimensions and type as the input value of x.
;KEYWORDS:
;   name:  a string that is appended to the input string.
;EXAMPLES:
;   name
;
;-

function rotate_data,data,rotmatrix,name=name

case size(/type,data) of
   7: begin                                       ; string
      names = tnames(data,nn)
      for i=0L,nn-1 do begin
         get_data,names[i],data=tempstr,alimit=limits
         if size(/type,tempstr) ne 8 then return,'NULLDATA'
         newstr = rotate_data(tempstr,rotmatrix,name=name)
         newname = names[i]+'_'+name
         store_data,newname,data=newstr,dlimit=limits
      endfor
         return,newname
      end
   8: begin                                       ; structure
      temp = data
      if size(/type,rotmatrix) eq 7 then begin
          rvec = data_cut(rotmatrix,temp.x)
          for i = 0l,n_elements(temp.x)-1 do begin
             rmat = rot_mat(reform(rvec[i,*]))
             temp.y[i,*] = data.y[i,*] # rmat
          endfor
          if not keyword_set(name) then name =  'R('+rotmatrix+')'
          return,temp
      endif
      newval = rotate_data(data.y,rotmatrix)
      temp.y = newval
      if not keyword_set(name) then name =  'rot'
      return,temp
      end
   else: begin                                    ; normal arrays
      return, data # rotmatrix
      end
endcase

end








