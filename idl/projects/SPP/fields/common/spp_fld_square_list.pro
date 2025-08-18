; Helper function to add padding to a ragged list of vectors
; to allow the ToArray function to transform the list to an IDL array

function spp_fld_square_list, list_input

  max_len = 0
  min_len = -1
  fill_val = !VALUES.F_NAN

  foreach item, list_input do begin

    if n_elements(item) GT max_len then begin
      max_len = n_elements(item)
      print, 'max length:', max_len
    end

    if n_elements(item) LT min_len or min_len LT 0 then begin
      min_len = n_elements(item)
      print, 'min length:', min_len
    end

  end

  if max_len EQ min_len then return, list_input

  square_list = list()

  foreach item, list_input do begin

    if n_elements(item) LT max_len then begin

      pad = make_array(max_len - n_elements(item), val = fill_val)

      square_list.Add, [item, pad]

    endif else begin

      square_list.Add, item

    endelse

  end

  return, square_list

end
