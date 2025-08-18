function get_mms_selections_file, type, start_time=start_time, end_time=end_time,  $
  local_dir=local_dir, filename= filename
  ;return the latest if no times specified

  ; Build query.
  ; Start by building an array of arguments based on inputs.
  ; Many values may be arrays so join with ",".
  ; Note that a single value will be treated as an array of one by IDL.
  query_args = ["hack"] ;IDL doesn't allow empty arrays before version 8.
  if n_elements(filename)   gt 0 then query_args = [query_args, "file=" + strjoin(filename, ",")]
  if n_elements(start_time) gt 0 then query_args = [query_args, "start_time=" + start_time]
  if n_elements(end_time)   gt 0 then query_args = [query_args, "end_time=" + end_time]
  
  ; Join query args with "&". If there are no query args, return only the latest file.
  query = ""
  if n_elements(query_args) eq 1 then latest=1  $  ;no args so default to latest
  else  query = strjoin(query_args[1:*], "&") ;drop the "hack"
  
  ; Execute the query.
  ; Allow more than default number of files since they are small
  ; and when the limit is exceeded a unit test breaks
  status = download_mms_files(type, query, local_dir=local_dir, latest=latest, max_files=10000)

  return, status  
end

