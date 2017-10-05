FUNCTION eva_sitl_strct_sort, FOMstr
  idx = sort(FOMstr.START)
  s = FOMstr
  str_element,/add,s,'START',FOMStr.START[idx]
  str_element,/add,s,'STOP',FOMStr.STOP[idx]
  str_element,/add,s,'FOM',FOMStr.FOM[idx]
  str_element,/add,s,'SEGLENGTHS',FOMStr.SEGLENGTHS[idx]
  str_element,/add,s,'SOURCEID',FOMStr.SOURCEID[idx]
  str_element,/add,s,'DISCUSSION',FOMStr.DISCUSSION[idx]
  return, s
END
