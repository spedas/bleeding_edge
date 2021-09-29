; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-12-04 12:32:15 -0800 (Tue, 04 Dec 2018) $
; $LastChangedRevision: 26232 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/magSwing/spp_read_ply.pro $
; For now this is a crib sheet. Also, "kludge" is nonfunctional any more, pending removal.

pro spp_read_ply, kludge = kludge, output = output, step = step, nframes = nframes
  
  if ~keyword_set(step) then step = 3
  if ~keyword_set(output) then output = 5
  if ~keyword_set(nframes) then nframes = 10
  ;; -- need to relocate these files and commit them to a common directory -- ;;
  if keyword_set(output) and nframes eq 20 then begin ; some of these may not exist
    if output eq 4 and step eq 3 then filePLY = 'Documents/SPANE/MagSwingTest/ComputerVisionResults/apl_5p7p3_x20_stereo_output4.ply'
    if output eq 4 and step eq 4 then filePLY = 'Documents/SPANE/MagSwingTest/ComputerVisionResults/apl_5p7p4_x20_stereo_output4.ply'
    if output eq 5 and step eq 3 then filePLY = 'Documents/SPANE/MagSwingTest/ComputerVisionResults/apl_5p7p3_x20_stereo_output5.ply'
    if output eq 5 and step eq 4 then filePLY = 'Documents/SPANE/MagSwingTest/ComputerVisionResults/apl_5p7p4_x20_stereo_output5.ply'
  endif
  if keyword_set(output) and nframes eq 10 then begin ; some of these may not exist.
    if output eq 4 and step eq 3 then filePLY = 'Documents/SPANE/MagSwingTest/ComputerVisionResults/apl_5p7p3_x10_stereo_output4.ply'
    if output eq 4 and step eq 4 then filePLY = 'Documents/SPANE/MagSwingTest/ComputerVisionResults/apl_5p7p4_x10_stereo_output4.ply'
    if output eq 5 and step eq 3 then filePLY = 'Documents/SPANE/MagSwingTest/ComputerVisionResults/apl_5p7p3_x10_stereo_output5.ply'
    if output eq 5 and step eq 4 then filePLY = 'Documents/SPANE/MagSwingTest/ComputerVisionResults/apl_5p7p4_x10_stereo_output5.ply'
  endif
  if keyword_set(kludge) then filePLY = 'Documents/SPANE/MagSwingTest/ComputerVisionResults/5p7p3/stereo_colorized.ply'
  
  cameraSep = 2.258568 ; in meters
  dataTags = {coord: [0.,0.,0.], rotMat: [[0.,0.,0.],[0.,0.,0.],[0.,0.,0.]], colRGB: [0,0,0]}
  plyData = read_asc(filePLY[0], format = dataTags, nheader = 19, headers = headerval)
  ;plyIndexHolder = where(plydata.colrgb[2]) ; not sure if I care about the index
  ;str_element, /add, plyIndexHolder, 
  camData = plyData[where((plyData.colrgb[1] eq 255) and (plyData.colrgb[0] eq 0) and (plyData.colrgb[2] eq 0))]
  camData1 = camData[0:(n_elements(camData)/2 - 1)]
  camData2 = camData[n_elements(camData)/2: -1]
  ;; --- another kludge: remove erroneous points from Cam1 -- ;;
  if output eq 4 then begin
    camData1[53].coord = (camData1[52].coord + camData1[54].coord)/2
    camData1[53].rotMat = (camData1[52].rotMat + camData1[54].rotMat)/2
    camData1[57].coord = (camData1[56].coord + camData1[58].coord)/2
    camData1[57].rotMat = (camData1[56].rotMat + camData1[58].rotMat)/2
  endif
  ;;--- Following Section is a Kludge to re-arrange points in a logical order (the original was scrambled) ---;;
  ;;--- These numbers were picked by inspecting the frame numbers manually ---;;
  if keyword_set(kludge) then begin
    a = indgen(n_elements(camData1))
    b = a[where(a[0:177] mod 11 ne 0)]
    c = a[where(a[0:177] mod 11 eq 0)]
    camData1no11s = camData1[b]
    camData2no11s = camData2[b]
    camData111s = camData1[c]
    camData211s = camData2[c]
    camData1fix = [camData111s, camData1[-28:-1], camData1no11s]
    camData2fix = [camData211s, camData2[-28:-1], camData2no11s]
  endif
  ;; --- find distance between the points --- ;;
  distance = sqrt((camData1.coord[0] - camData2.coord[0])^2 + (camData1.coord[1] - camData2.coord[1])^2 + (camData1.coord[2] - camData2.coord[2])^2)
  ;; --- scale everything to the right size --- ;;
  scaleFactor = cameraSep / mean(distance)
  camData1scale = camData1
  camData2scale = camData2
  camData1scale.coord = camData1.coord * scaleFactor
  camData2scale.coord = camData2.coord * scaleFactor
  distanceScale = distance * scaleFactor
  ;; -- Following Section is a Kludge for Non-Stereo Rotation Files -- ;;
  meanX = mean(camData.coord[0])
  meanY = mean(camData.coord[1])
  meanZ = mean(camData.coord[2])
  print, 'Mean X, Y, Z', meanX, meanY, meanZ
  ;; -- Easiest way to calculate magnitude?? -- ;;
  xyz_to_polar, transpose(camData.coord), mag = camMagn, theta = thetaMagn, phi = phiMagn
  maxCamMagn = max(camMagn)
  minCamMagn = min(camMagn)
  minIndex = where(camMagn eq minCamMagn)
  maxIndex = where(camMagn eq maxCamMagn)
  ;; did davin write xyz_to_polar? is theta from z axis or phi plane? ;;
  

  print, 'dbug Pause!'
end