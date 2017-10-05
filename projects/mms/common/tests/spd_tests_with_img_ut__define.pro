;+
;
; This object adds a method (check_img) to MGunit for checking that 2 PNGs are (roughly) equal
; 
; Note: 
;   allows for minor, off-by-one differences by verifying the difference isn't entirely 255s and 1s 
;   (which can occur with the *_part_products routines)
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-07-17 11:55:12 -0700 (Mon, 17 Jul 2017) $
; $LastChangedRevision: 23620 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/spd_tests_with_img_ut__define.pro $
;-


function spd_tests_with_img_ut::check_img, old_img, new_img
  previous = read_png(old_img)
  new = read_png(new_img)
  diff = new-previous
  wherenot0 = where(diff ne 0, nonzerocount)
  if nonzerocount ne 0 then begin
    where255 = where(diff eq 255, count255)
    if count255 ne 0 then diff[where255] = 1
  endif
  assert, total(diff[wherenot0]) eq nonzerocount, 'Problem comparing the images: ' + old_img + ' and ' + new_img
  return, 1
end

pro spd_tests_with_img_ut__define
  define = { spd_tests_with_img_ut, inherits MGutTestCase }
end
