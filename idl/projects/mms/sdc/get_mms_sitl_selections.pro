function get_mms_sitl_selections, start_time=start_time, end_time=end_time,  $
  local_dir=local_dir, filename= filename
  ;return the latest if no times specified

  status = get_mms_selections_file("sitl_selections", start_time=start_time, $
    end_time=end_time, local_dir=local_dir, filename=filename)

  return, status  
end

