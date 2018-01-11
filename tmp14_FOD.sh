
# Fibre orientation distribution estimation
if [ ! -f $PRD/connectivity/wm_CSD$lmax.mif ]; then
  # Both for multishell and single shell since we use dhollander in the 
  # single shell case
  # see: http://community.mrtrix.org/t/wm-odf-and-response-function-with-dhollander-option---single-shell-versus-multi-shell/572/4
  echo "calculating fod on multishell or single shell data"
  view_step=1
  dwi2fod msmt_csd $PRD/connectivity/dwi.mif \
          $PRD/connectivity/response_wm.txt \
          $PRD/connectivity/wm_CSD$lmax.mif \
          $PRD/connectivity/response_gm.txt \
          $PRD/connectivity/gm_CSD$lmax.mif \
          $PRD/connectivity/response_csf.txt \
          $PRD/connectivity/csf_CSD$lmax.mif \
          -mask $PRD/connectivity/mask_dilated.mif -force \
          -nthreads "$NB_THREADS"
fi
if [ "$view_step" = 1 -a "$CHECK" = "yes" ] || [ "$CHECK" = "force" ] && [ -n "$DISPLAY" ]; then
  echo "check ODF image"
  view_step=0
  mrconvert $PRD/connectivity/wm_CSD$lmax.mif - -coord 3 0 \
  -nthreads "$NB_THREADS" -force \
  | mrcat $PRD/connectivity/csf_CSD$lmax.mif \
          $PRD/connectivity/gm_CSD$lmax.mif - \
          $PRD/connectivity/tissueRGB.mif -axis 3 -nthreads "$NB_THREADS" \
          -force
  mrview $PRD/connectivity/tissueRGB.mif \
         -odf.load_sh $PRD/connectivity/wm_CSD$lmax.mif 
fi



