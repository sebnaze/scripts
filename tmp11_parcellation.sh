
# generating FSl brain.mgz
if [ ! -f $PRD/connectivity/brain.nii.gz ]; then
  # brain.mgz seems to be superior to diff to T1
  # as the main problem for registration is the wmgm interface that we want to
  # remove and BET stripping is unfortunate in many situations, 
  # and FS pial eddited volumes already present
  # stride from FS to FSL: RAS to LAS
  # see: http://www.grahamwideman.com/gw/brain/fs/coords/fscoords.htm
  # we could do
  # mrconvert $FS/$SUBJ_ID/mri/brain.mgz $PRD/connectivity/brain.nii.gz \
  #           -datatype float32 -stride -1,+2,+3,+4 -force -nthreads "$NB_THREADS" 
  # instead we use the pure brain from aparc+aseg:
  echo "generating masked brain in FSL orientation"
  mri_binarize --i $FS/$SUBJ_ID/mri/aparc+aseg.mgz \
               --o $FS/$SUBJ_ID/mri/aparc+aseg_mask.mgz --min 0.5 --dilate 1 
  #mri_mask $FS/$SUBJ_ID/mri/T1.mgz $FS/$SUBJ_ID/mri/aparc+aseg_mask.mgz \
  mri_mask $FS/$SUBJ_ID/mri/brain.mgz $FS/$SUBJ_ID/mri/aparc+aseg_mask.mgz \
           $FS/$SUBJ_ID/mri/brain_masked.mgz
  #mrconvert $FS/$SUBJ_ID/mri/brain.mgz $PRD/connectivity/brain.nii.gz \
  mrconvert $FS/$SUBJ_ID/mri/brain_masked.mgz $PRD/connectivity/brain.nii.gz \
            -force -datatype float32 -stride -1,+2,+3,+4 
fi



# aparc+aseg to FSL
if [ ! -f $PRD/connectivity/aparc+aseg.nii.gz ]; then
  echo "generating FSL orientation for aparc+aseg"
  # stride from FS to FSL: RAS to LAS
  mrconvert $FS/$SUBJ_ID/mri/aparc+aseg.mgz \
            $PRD/connectivity/aparc+aseg.nii.gz -stride -1,+2,+3,+4 -force \
            -nthreads "$NB_THREADS" 
fi

# check orientations
if [ ! -f $PRD/connectivity/aparc+aseg_reorient.nii.gz ]; then
  echo "reorienting the region parcellation"
  view_step=1
  "$FSL"fslreorient2std $PRD/connectivity/aparc+aseg.nii.gz \
                  $PRD/connectivity/aparc+aseg_reorient.nii.gz
fi
# check parcellation to brain.mgz
if [ "$view_step" = 1 -a "$CHECK" = "yes" ] || [ "$CHECK" = "force" ] && [ -n "$DISPLAY" ]; then
  # TODO: mrview discrete colour scheme?
  echo "check parcellation"
  echo "if it's correct, just close the window." 
  echo "Otherwise... well, it should be correct anyway"
  view_step=0
  mrview $PRD/connectivity/brain.nii.gz \
         -overlay.load $PRD/connectivity/aparc+aseg_reorient.nii.gz \
         -overlay.opacity 0.5 -norealign
fi

# aparcaseg to diff by inverse transform
if [ ! -f $PRD/connectivity/aparcaseg_2_diff.nii.gz ]; then
  view_step=1
  if [ "$REGISTRATION" = "regular" ] || [ "$REGISTRATION" = "pseudo" ]; then
    # 6 dof; see:
    # http://web.mit.edu/fsl_v5.0.8/fsl/doc/wiki/FLIRT(2f)FAQ.html#What_cost_function_and.2BAC8-or_degrees_of_freedom_.28DOF.29_should_I_use_in_FLIRT.3F
    echo "register aparc+aseg to diff"
    "$FSL"flirt -in $PRD/connectivity/lowb.nii.gz \
                -out $PRD/connectivity/lowb_2_struct.nii.gz \
                -ref $PRD/connectivity/brain.nii.gz \
                -omat $PRD/connectivity/diffusion_2_struct.mat -dof 6 \
                -searchrx -180 180 -searchry -180 180 -searchrz -180 180 \
                -cost mutualinfo
  elif [ "$REGISTRATION" = "boundary" ]; then
    echo "register aparc+aseg to diff using bbr cost function in FLIRT"
    # as per http://community.mrtrix.org/t/registration-of-structural-and-diffusion-weighted-data/203/8
    "$FSL"fast -N -o $PRD/connectivity/brain_fast $PRD/connectivity/brain.nii.gz 
    "$FSL"fslmaths $PRD/connectivity/brain_fast_pve_2.nii.gz -thr 0.5 \
                   -bin $PRD/connectivity/brain_fast_wmmask.nii.gz
    # first flirt to get an init transform mat
    "$FSL"flirt -in $PRD/connectivity/lowb.nii.gz \
                -ref $PRD/connectivity/brain.nii.gz \
                -omat $PRD/connectivity/flirt_bbr_tmp.mat -dof 6 
    # flirt using bbr cost
    "$FSL"flirt -in $PRD/connectivity/lowb.nii.gz \
                -out $PRD/connectivity/lowb_2_struct.nii.gz \
                -ref $PRD/connectivity/brain.nii.gz \
                -omat $PRD/connectivity/diffusion_2_struct.mat \
                -wmseg $PRD/connectivity/brain_fast_wmmask.nii.gz \
                -init $PRD/connectivity/flirt_bbr_tmp.mat \
                -schedule $FSLDIR/etc/flirtsch/bbr.sch -dof 6 \
                -searchrx -180 180 -searchry -180 180 -searchrz -180 180 \
                -cost bbr 
  fi
  transformconvert $PRD/connectivity/diffusion_2_struct.mat \
                   $PRD/connectivity/lowb.nii.gz \
                   $PRD/connectivity/brain.nii.gz \
                   flirt_import $PRD/connectivity/diffusion_2_struct_mrtrix.txt \
                   -force 
  mrtransform $PRD/connectivity/aparc+aseg_reorient.nii.gz \
              $PRD/connectivity/aparcaseg_2_diff.nii.gz \
              -linear $PRD/connectivity/diffusion_2_struct_mrtrix.txt \
              -inverse -datatype uint32 -force -nthreads "$NB_THREADS"
fi

# brain to diff by inverse transform
if [ ! -f $PRD/connectivity/brain_2_diff.nii.gz ]; then
  echo "register brain to diff"
  view_step=1
  mrtransform $PRD/connectivity/brain.nii.gz \
              $PRD/connectivity/brain_2_diff.nii.gz \
              -linear $PRD/connectivity/diffusion_2_struct_mrtrix.txt \
              -inverse -force 
fi
# check brain and parcellation to diff
if [ "$view_step" = 1 -a "$CHECK" = "yes" ] || [ "$CHECK" = "force" ] && [ -n "$DISPLAY" ]; then
  echo "check parcellation registration to diffusion space"
  echo "if it's correct, just close the window."
  echo "Otherwise you will have to do the registration by hand"
  view_step=0
  mrview $PRD/connectivity/brain_2_diff.nii.gz \
         $PRD/connectivity/lowb.nii.gz \
         -overlay.load $PRD/connectivity/aparcaseg_2_diff.nii.gz \
         -overlay.opacity 0.5 -norealign
fi


