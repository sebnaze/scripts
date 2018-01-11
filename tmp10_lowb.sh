# low b extraction to FSL
if [ ! -f $PRD/connectivity/lowb.nii.gz ]; then
  view_step=1
  if [ "$REGISTRATION" = "regular" ] || [ "$REGISTRATION" = "boundary" ]; then
    echo "extracting b0 vols for registration"
    dwiextract $PRD/connectivity/dwi.mif $PRD/connectivity/lowb.mif \
 		-bzero -force -nthreads "$NB_THREADS" 
                #-fslgrad $PRD/connectivity/bvecs $PRD/connectivity/bvals \ 
    # stride from mrtrix to FSL, RAS to LAS
    # see: http://mrtrix.readthedocs.io/en/latest/getting_started/image_data.html
    mrconvert $PRD/connectivity/lowb.mif $PRD/connectivity/lowb.nii.gz \
              -stride -1,+2,+3,+4 -force -nthreads "$NB_THREADS" 
              #-fslgrad $PRD/connectivity/bvecs $PRD/connectivity/bvals \ 
    # for visualization 
    mrmath  $PRD/connectivity/lowb.mif mean $PRD/connectivity/meanlowb.mif \
            -axis 3 -force -nthreads "$NB_THREADS"
  elif [ "$REGISTRATION" = "pseudo" ]; then
    # lowb-pseudo brain for pseudo registration
    echo "generate lowb-pseudo vols for pseudo registration"
    # Generate transform image (dwi) for pseudo registration method: 
    # see: Bhushan C, et al. Neuroimage. 2015 Jul 15;115:269-8
    # used in: https://github.com/BIDS-Apps/MRtrix3_connectome/blob/master/run.py
    dwiextract $PRD/connectivity/dwi.mif -bzero - \
    | mrmath - mean - -axis 3 \
    | mrcalc 1 - -divide $PRD/connectivity/mask.mif -multiply - \
    | mrconvert - - -stride -1,+2,+3 \
    | mrhistmatch - $PRD/connectivity/brain.nii.gz \
                  $PRD/connectivity/lowb.nii.gz
  fi
fi
if [ "$view_step" = 1 -a "$CHECK" = "yes" ] || [ "$CHECK" = "force" ] && [ -n "$DISPLAY" ]; then
  echo "check lowb image"
  view_step=0
  mrview $PRD/connectivity/lowb.mif \
         -overlay.load $PRD/connectivity/dwi.mif \
         -overlay.opacity 1. -norealign
fi


