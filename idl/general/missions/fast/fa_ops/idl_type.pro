function idl_type,x

types = $
  ['undefined','byte','integer','long','float','double', $
   'complex','string','structure','double complex','pointer', $
   'object reference']

sx = size(x)
ti = sx(sx(0)+1)

return,types(ti)
end
