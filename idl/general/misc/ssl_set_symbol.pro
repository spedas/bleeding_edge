
;+
;Procedure: ssl_set_symbol
;
;Purpose: 
;   1) Set the user defined plotting symbol to be used with psym=8, 
;              or
;   2) Return a graphics object of the specified symbol
;         
;Calling Sequence:
;    ssl_set_symbol, index [,fill=fill] [,size=size] [,fail=fail]
;                       [,object=object, [,obj_size=obj_size] [,color=color]]
;
;Arguments:
;  INDEX: Number of the symbol that is desired:
;         1: Plus sign
;         2: Star
;         3: Circle
;         4: Diamond
;         5: Triangle
;         6: Square
;         7: X
;        42: Lemniscate
;  FILL: Flag to fill the symbol (solid)
;  SIZE: Number specifying the size of the symbol (default=1.0)
;        (not valid if used with OBJECT)
;  OBJECT: If called this keyword will return an IDLgrSymbol object
;          of the requested type
;  OBJ_SIZE: Two element array specifying the returned graphics
;            object's x and y size respecively.
;  COLOR: The color of the returned graphics object; may be specified as an  
;         index or as a three-element vector [red, green, blue].
;  FAIL: This keword will contain a message if any errors are encountered 
;
;Examples:
;  Set to a filled circle:
;  
;    ssl_set_symbol, 3, /fill
;    
;  Set to an large, unfilled triangle:
;  
;    ssl_set_symbol, 5, size = 5
;    
;  Get IDLgrSymbol for a filled diamond:
;  
;    ssl_set_symbol, 4, obj=obj, /fill
;
;Caveats:
; Non-fillable symbols such as Asterisks and Plus Signs will not
; return graphics objects if /fill is set.
;
;Other: 
; This routine was primarily developed as a method of drawing 
; filled symbols; however, any number of custom symbols may be added 
; by specifying the x and y variables in the main case statment.
;
;-

pro ssl_set_symbol, index, fill=fill, size=size, $
                       object=object, obj_size=obj_size, color=color, $
                       fail=fail
    

    compile_opt idl2, hidden


  fail=''

  i = long(index)
  if arg_present(object) then s = 1.
  s = keyword_set(size) ? float(size):1. ;default size
    
  
  ; To add a new symbol simply drop a new index into this case statement
  case i of
    
    ;Plus sign
    1: begin
      fill = 0 ;do not fill
      
      x = [0,s,-s,0,0, 0,0]
      y = shift(x,3)
    end
    
    
    ;Asterisk
    2: begin
      n = 2*(5)+1 ;2*number of points + 1 (odd)
      fill = 0 ;do not fill

      x = s * cos( findgen(n)/(n-1) * 2*!pi + !pi/2)
      y = s * sin( findgen(n)/(n-1) * 2*!pi + !pi/2)

      t = 2*indgen(n/2) + 1
      
      x[t] = 0.
      y[t] = 0.
    end
    
    
    ;Circle 
    3: begin
      n = 21 ;number of points
      x = s * cos( findgen(n)/(n-1) * 2*!pi )
      y = s * sin( findgen(n)/(n-1) * 2*!pi )
      
      ;kludge for graphics object
      if keyword_set(obj_size) then obj_size = obj_size / 4.
    end
    
    
    ;Diamond
    4: begin
      x = [ s, 0, -s, 0]
      y = shift(x,1)
    end
    
    
    ;Triangle
    5: begin
      n = 4  ;number of points
      x = s * cos( findgen(n)/(n-1) * 2*!pi + !pi/2)
      y = s * sin( findgen(n)/(n-1) * 2*!pi + !pi/2)
    end
    
    
    ;Square
    6: begin
      x = [ s, s, -s, -s]
      y = shift(x,1)
    end
  
    
    ;X
    7: begin
      n = 2 *(4) + 1 ;2*number of points + 1 (odd)
      fill = 0 ;do not fill

      x = s * cos( findgen(n)/(n-1) * 2*!pi + !pi/4)
      y = s * sin( findgen(n)/(n-1) * 2*!pi + !pi/4)

      t = 2*indgen(n/2) + 1
      
      x[t] = 0.
      y[t] = 0.
    end
  
  
    ;Lemniscate
    42: begin
      n = 21 ;number of points
      fill = 0 ;do not fill
      
      t = findgen(n)/(n-1) * 2*!pi
      
      x = s * cos(t) / ( 1 + sin(t)^2 )
      y = s * cos(t) * sin(t) / ( 1 + sin(t)^2 )
    end


    else: begin
      fail = 'Unrecognized symbol index: ' +strtrim(i,2)
      return
    end    

  endcase
  
  
  ;Return graphics object if requested
  ;Otherwise, set user define plotting symbol
  ;
  ; *Non-filled symbols have issues being drawn as graphics objects
  ;  and will be discarded for now (such symbols should already be 
  ;  usable with IDL object graphics)
  if arg_present(object) && keyword_set(fill) then begin
  
    if ~keyword_set(obj_size) then obj_size = [1.,1.]
  
    dummy=obj_new('IDLgrPolygon', x, y, color=color)  
    object = OBJ_NEW('IDLgrSymbol', dummy, size=obj_size)
  
  endif else begin
  
    usersym, x, y, fill=fill
  
  endelse

end
