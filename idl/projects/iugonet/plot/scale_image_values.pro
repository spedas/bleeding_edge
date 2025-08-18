;+
;	PROCEDURE scale_image_values
;
; :DESCRIPTION:
;    Scale values of image into the designated range.
;
; :PARAMS:
;    image:
;    range:
;    image_out:
;
; :AUTHOR:
;    Yoshimasa Tanaka (E-mail: ytanaka@nipr.ac.jp)
;
; :HISTORY:
;    2014/07/08: Created
;
;-
pro scale_image_values, image, range, image_out

;Set color level for contour
cmax = !d.table_size-1
cmin = 8L
cnum = cmax-cmin

;Calculate the color index for image data
image_out = (image-range[0]) / (range[1]-range[0]) * ( cnum ) + cmin  
image_out = long( ( image_out > cmin ) < cmax )

end
