function mms_get_science_file_names, filename=filename, sc_id=sc_id, $
instrument_id=instrument_id, data_rate_mode=data_rate_mode, $
data_level=data_level, descriptor=descriptor, start_date=start_date, end_date=end_date

  ; Web API defined with lower case.
  if n_elements(sc_id)          gt 0 then sc_id          = strlowcase(sc_id)
  if n_elements(instrument_id)  gt 0 then instrument_id  = strlowcase(instrument_id)
  if n_elements(data_rate_mode) gt 0 then data_rate_mode = strlowcase(data_rate_mode)
  if n_elements(data_level)     gt 0 then data_level     = strlowcase(data_level)

  ; Build query.
  ; Start by building an array of arguments based on inputs.
  ; Many values may be arrays so join with ",".
  ; Note that a single value will be treated as an array of one by IDL.
  query_args = ["hack"] ;IDL doesn't allow empty arrays before version 8.
  if n_elements(filename)       gt 0 then query_args = [query_args, "file=" + strjoin(filename, ",")]
  if n_elements(sc_id)          gt 0 then query_args = [query_args, "sc_id=" + strjoin(sc_id, ",")] 
  if n_elements(instrument_id)  gt 0 then query_args = [query_args, "instrument_id=" + strjoin(instrument_id, ",")]
  if n_elements(data_rate_mode) gt 0 then query_args = [query_args, "data_rate_mode=" + strjoin(data_rate_mode, ",")]
  if n_elements(data_level)     gt 0 then query_args = [query_args, "data_level=" + strjoin(data_level, ",")]
  if n_elements(descriptor)     gt 0 then query_args = [query_args, "descriptor=" + strjoin(descriptor, ",")]
  if n_elements(start_date)     gt 0 then query_args = [query_args, "start_date=" + start_date]
  if n_elements(end_date)       gt 0 then query_args = [query_args, "end_date=" + end_date]
  
  ; Join query args with "&", drop the "hack"
  if n_elements(query_args) lt 2 then query = '' $
  else query = strjoin(query_args[1:*], "&")
  
  ; Execute the query.
  names = get_mms_file_names("science", query=query)

  return, names
end



