
# TOCHECK: Masking step before or after biascorrect?
# Native-resolution mask creation
if [ ! -f $PRD/connectivity/mask_native.mif ]; then
  echo "create dwi mask"
  view_step=1
  dwi2mask $PRD/connectivity/predwi_denoised_preproc.mif \
           $PRD/connectivity/mask_native.mif -nthreads "$NB_THREADS"
fi
# check mask file
if [ "$view_step" = 1 -a "$CHECK" = "yes" ] || [ "$CHECK" = "force" ]  && [ -n "$DISPLAY" ]; then
  echo "check native mask mif file"
  view_step=0
  mrview $PRD/connectivity/predwi_denoised_preproc.mif \
         -overlay.load $PRD/connectivity/mask_native.mif \
         -overlay.opacity 0.5
fi

# Bias field correction
if [ ! -f $PRD/connectivity/predwi_denoised_preproc_bias.mif ]; then
  # ANTS seems better than FSL
  # see http://mrtrix.readthedocs.io/en/0.3.16/workflows/DWI_preprocessing_for_quantitative_analysis.html
  if [ -n "$ANTSPATH" ]; then
    echo "bias correct using ANTS"
    dwibiascorrect $PRD/connectivity/predwi_denoised_preproc.mif \
                   $PRD/connectivity/predwi_denoised_preproc_bias.mif \
                   -mask $PRD/connectivity/mask_native.mif \
                   -bias $PRD/connectivity/B1_bias.mif -ants -force \
                   -nthreads "$NB_THREADS"
  else
    echo "bias correct using FSL"
    dwibiascorrect $PRD/connectivity/predwi_denoised_preproc.mif \
                   $PRD/connectivity/predwi_denoised_preproc_bias.mif \
                   -mask $PRD/connectivity/mask_native.mif \
                   -bias $PRD/connectivity/B1_bias.mif -fsl -force \
                   -nthreads "$NB_THREADS"
  fi
fi
# check bias field correction
if [ "$view_step" = 1 -a "$CHECK" = "yes" ] || [ "$CHECK" = "force" ] && [ -n "$DISPLAY" ]; then
  echo "check bias field correction"
  mrview $PRD/connectivity/predwi.mif \
         $PRD/connectivity/predwi_denoised_preproc.mif \
         $PRD/connectivity/predwi_denoised_preproc_bias.mif 
fi



