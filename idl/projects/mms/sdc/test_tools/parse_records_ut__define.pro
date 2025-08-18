pro parse_records_ut::setup
  compile_opt strictarr
  url = get_mms_sitl_connection(host='sdc-web2', port='8080', auth='0', /rebuild)
  
end


function parse_records_ut::test_empty_records
  compile_opt strictarr
  struct = {a:0, b:0, c:0}
  records = ''
  result = parse_records(records, struct)
  assert, result eq -1, 'Empty results should return -1'
  
  return, 1
end

function parse_records_ut::test_one_record
  compile_opt strictarr
  struct = {a:0, b:0, c:0}
  records = '1,2,3'
  result = parse_records(records, struct)
  
  assert, size(result, /type) eq 8, 'Result is not a structure'
  assert, n_elements(result) eq 1, 'Should have gotten only one record'
  assert, result[0].b eq 2, 'Did not get expected value'
  
  return, 1
end

function parse_records_ut::test_multiple_record
  compile_opt strictarr
  struct = {a:0, b:0, c:0}
  records = ['1,2,3','4,5,6','7,8,9']
  result = parse_records(records, struct)
  
  assert, size(result, /type) eq 8, 'Result is not a structure'
  assert, n_elements(result) eq 3, 'Should have gotten three records'
  assert, result[1].b eq 5, 'Did not get expected value'
  
  return, 1
end

function parse_records_ut::test_skip_record_with_too_few_samples
  compile_opt strictarr
  struct = {a:0, b:0, c:0}
  records = ['1,2,3','4,6','7,8,9']
  result = parse_records(records, struct)
  
  assert, size(result, /type) eq 8, 'Result is not a structure'
  assert, n_elements(result) eq 2, 'Should have gotten two valid records'
  assert, result[1].b eq 8, 'Did not get expected value'
  
  return, 1
end

function parse_records_ut::test_skip_record_with_too_many_samples
  compile_opt strictarr
  struct = {a:0, b:0, c:0}
  records = ['1,2,3','4,5,6,7','7,8,9']
  result = parse_records(records, struct)
  
  assert, size(result, /type) eq 8, 'Result is not a structure'
  assert, n_elements(result) eq 2, 'Should have gotten two valid records'
  assert, result[1].b eq 8, 'Did not get expected value'
 
  return, 1
end

function parse_records_ut::test_skip_record_with_invalid_type
  compile_opt strictarr
  struct = {a:0, b:0, c:0}
  records = ['1,2,3','4,"foo",6','7,8,9']
  result = parse_records(records, struct)
  
  assert, size(result, /type) eq 8, 'Result is not a structure'
  assert, n_elements(result) eq 2, 'Should have gotten two valid records'
  assert, result[1].b eq 8, 'Did not get expected value'
  
  return, 1
end

function parse_records_ut::test_first_record_invalid
  compile_opt strictarr
  struct = {a:0, b:0, c:0}
  records = ['1,2','4,5,6','7,8,9']
  result = parse_records(records, struct)
  
  assert, size(result, /type) eq 8, 'Result is not a structure'
  assert, n_elements(result) eq 2, 'Should have gotten two valid records'
  assert, result[1].b eq 8, 'Did not get expected value'
  
  return, 1
end

function parse_records_ut::test_last_record_invalid
  compile_opt strictarr
  struct = {a:0, b:0, c:0}
  records = ['1,2,3','4,5,6','7,8']
  result = parse_records(records, struct)
  
  assert, size(result, /type) eq 8, 'Result is not a structure'
  assert, n_elements(result) eq 2, 'Should have gotten two valid records'
  assert, result[1].b eq 5, 'Did not get expected value'
  
  return, 1
end

function parse_records_ut::test_all_records_invalid
  compile_opt strictarr
  struct = {a:0, b:0, c:0}
  records = ['1','4,5','7,8,9,10']
  result = parse_records(records, struct)
  
  assert, result eq -1, 'No valid results should return -1'
  
  return, 1
end

function parse_records_ut::test_inputs_are_immutable
  compile_opt strictarr
  struct = {a:0, b:0, c:0}
  records = ['1,2,3','4,5,6','7,8,9']
  result = parse_records(records, struct)
 
  assert, records[1] eq '4,5,6', 'Function mutated input records'
  assert, struct.b eq 0, 'Function mutated input structure'
  assert, result[1].b eq 5, 'Did not get expected value'
  
  return, 1
end

function parse_records_ut::test_embedded_delimiters
  compile_opt strictarr
  struct = {a:'', b:'', c:''}
  records = ['a,b,c','d,e,f','g,h,i,j']
  result = parse_records(records, struct,/embedded_delimiters)

  assert, size(result, /type) eq 8, 'Result is not a structure'
  assert, n_elements(result) eq 3, 'Should have gotten three valid records'
  assert, result[2].c eq 'i,j', 'Did not get expected value'

  return, 1
end

pro parse_records_ut__define
  compile_opt strictarr
  
  define = { parse_records_ut, inherits MGutTestCase }
end