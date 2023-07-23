;+
;
;NAME:
;rm_star_absint
;
;PURPOSE:
; Remove star lights with a median filter.
;
;SYNTAX:
; rm_star_absint, img0, img_out, img_size
;
;KEYWOARDS:
;  img0 = input the image data
;  img_out = output the image data that remove the star lights
;  img_size = tiff size (256 or 512)
;
;CODE:
;  A. Shinbori, 08/07/2022.
;
;MODIFICATIONS:
;
;
;ACKNOWLEDGEMENT:
; $LastChangedBy:
; $LastChangedDate:
; $LastChangedRevision:
; $URL $
;-

pro rm_star_absint, img0, img_out, img_size

  ;---Median filter size:
   width = 11
  
  ;---image size is not 512 --> change the width
   if img_size ne 512 then width = fix(width*(img_size/512.))
   
  ;---Calculate the median value: 
   med_img = median(img0, width)
  
  ;---Deviation of the raw image from the median value:
   star_img = img0 - med_img
  
  ;---Calculate the mean, variance, skewness, and kurtosis of a sample population contained in an n-element vector X:
   pix_0 = img_size/2 - img_size/4
   pix_1 = img_size/2 + img_size/4 - 1
   result = moment(star_img[pix_0:pix_1,pix_0:pix_1])
  
  ;---Calculate the threshold of star lights:
  ;---threshold = mean value + standard deviation:
   star_threshold = result[0] + sqrt(result[1])
   
  ;---Identify the number of non-star light positions with less than threshold value: 
   non_star_pos = where(star_img lt star_threshold, cnt)
  
  ;---The numer of non-star light positions is not zero --> the image value is zero at the star light positions: 
   if cnt ne 0 then star_img(non_star_pos) = 0
   
  ;---Substract the star light from the raw image data:
   img_out = img0 - star_img

end
