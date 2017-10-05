; how many digits do you want?  Add zeros to fill in the rest

function num2string, num, digits_requested
  nnum = n_elements (num)
  out_string = strarr (nnum)
  for J = 0L, nnum -1 do begin 
      n_digits=strlen (roundst (num[J]))
      if n_digits gt digits_requested then message, $
        'number of digits requested must be equal to or larger than that of number'
      if n_digits gt 4 or digits_requested gt 4 then message, $
        'numbers must be less than 10,000'
      case digits_requested of
          1: out_string [J] = strtrim (num[J])
          2: out_string [J] = strcompress(string(num[J]/10 mod 10), /rem)+$
            strcompress(string(num[J] mod 10), /rem)
          3: out_string [J] = $
            strcompress(string((num[J] - 1000*(num[J]/1000))/100), /rem)+$
            strcompress(string(num[J]/10 mod 10), /rem)+$
            strcompress(string(num[J] mod 10), /rem)
          4: out_string [J] = strcompress(string(num[J]/1000), /rem) +$
            strcompress(string((num[J] - 1000*(num[J]/1000))/100), /rem)+$
            strcompress(string(num[J]/10 mod 10), /rem)+$
            strcompress(string(num[J] mod 10), /rem)     
      endcase
  endfor
  return, out_string
end
