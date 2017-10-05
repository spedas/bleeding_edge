function get_mms_burst_segment_status, start_time=start_time, end_time=end_time, $
  is_pending=is_pending, data_segment_id=data_segment_id

  ;Define the structure template for the data segment record.
  struct = { data_segment,  $
             dataSegmentId  :0L,  $
             taiStartTime   :0UL,  $
             taiEndTime     :0UL,  $
             parameterSetId :"",  $
             fom            :0.0,  $
             isPending      :0,  $
             inPlayList     :0,  $
             status         :"",  $
             numEvalCycles  :0,  $
             sourceId       :"",  $
             createTime     :"",  $
             finishTime     :"",  $
             discussion     :"" $
           }

  ;Define the dataset name.
  dataset = "mms_burst_data_segment"
  ;Define the URL path.
  path = "mms/sdc/sitl/latis/dap/" + dataset + ".csv"
  
  ;Construct the LaTiS query.
  query = ""
  ;Add parameters, use tag names from struct.
  tags = tag_names(struct) ;Note, these will be all caps
  ntags = n_elements(tags)
  for itag = 0, ntags-2 do query = query + tags[itag] + ','
  query = query + tags[ntags-1]  ;last element without ","
  ;Add constraints
  if n_elements(data_segment_id) gt 0 then query = query + "&DATASEGMENTID=" + strtrim(data_segment_id,2)
  ;Time range: include segment if it is partially in the requested range
  if n_elements(start_time)      gt 0 then query = query + "&TAIENDTIME>"    + strtrim(string(start_time, format='(I10)'),2)
  if n_elements(end_time)        gt 0 then query = query + "&TAISTARTTIME<"  + strtrim(string(end_time, format='(I10)'),2)
  ;is_pending is effectively a boolean
  if n_elements(is_pending)      gt 0 then begin
    if (is_pending) then query = query + "&ISPENDING=1"  $
    else query = query + "&ISPENDING=0" 
  endif
    
  ;Execute the query. Get the results back in an array of structures.
  ;  or an error code or -1 if no results were found.
  result = execute_latis_query(path, query, struct, /embedded_delimiters)
    
  ;Print a warning if no data are found.
  if size(result, /type) ne 8 then if result eq -1 then  $
    printf, -2, "WARN: No burst segment found for query: " + query
    
  return, result
end
