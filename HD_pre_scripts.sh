#!/usr/bin/env bash

# check mandatory variables
if [ -z "$PRD" ]; then
  echo "PRD path missing"
  exit 1
fi

if [ -z "$SUBJ_ID" ]; then
  echo "SUBJ_ID path missing"
  exit 1
fi

## prepare surface files
mkdir -p "$PRD"/data "$PRD"/data/T1 "$PRD"/data/DWI "$PRD"/surface
mkdir -p "$FREESURFER_HOME"/subjects/"$SUBJ_ID"
mkdir -p "$PRD"/connectivity

# convert MRI file to nifti
mrconvert $PRD/data/T1/*.mgz $PRD/data/T1/T1.nii.gz -nthreads "$NB_THREADS"
mrconvert $PRD/mri/aparc+aseg.mgz $PRD/connectivity/aparc+aseg.nii.gz -nthreads "$NB_THREADS"
#cp $PRD/connectivity/aparc+aseg.nii.gz $PRD/connectivity/aparc+aseg_reorient.nii.gz 
#cp $PRD/connectivity/aparc+aseg.nii.gz $PRD/connectivity/aparcaseg_2_diff.nii.gz 

# copy directions gradients files
cp $PRD/data/DWI/*bvals_trans* $PRD/connectivity/bvals
cp $PRD/data/DWI/*bvecs_trans* $PRD/connectivity/bvecs

#mv "$PRD"/"$SUBJ_ID"/T1w/"$SUBJ_ID"/* "$FS"/"$SUBJ_ID"/

##  prepare connectivity files
##############################

# predwi
mrconvert "$PRD"/data/DWI/data.nii.gz \
          "$PRD"/connectivity/predwi.mif \
          -fslgrad "$PRD"/connectivity/bvecs "$PRD"/connectivity/bvals \
          -datatype float32 -force
# denoise
mrconvert "$PRD"/data/DWI/*_dti_denoised_FA.nii.gz \
          "$PRD"/connectivity/predwi_denoised.mif \
          -datatype float32 -force
          #-fslgrad "$PRD"/connectivity/bvecs "$PRD"/connectivity/bvals \
# ecc
mrconvert "$PRD"/data/DWI/*_ecc.nii.gz \
          "$PRD"/connectivity/predwi_denoised_preproc.mif \
          -fslgrad "$PRD"/connectivity/bvecs "$PRD"/connectivity/bvals \
          -datatype float32 -force
# debiased
mrconvert "$PRD"/data/DWI/*_ecc_debiased.nii.gz \
          "$PRD"/connectivity/predwi_denoised_preproc_bias.mif \
          -fslgrad "$PRD"/connectivity/bvecs "$PRD"/connectivity/bvals \
          -datatype float32 -force
# denoise again?
mrconvert "$PRD"/data/DWI/*_ecc_debiased_denoise.nii.gz \
          "$PRD"/connectivity/predwi_denoised_preproc_bias.mif \
          -fslgrad "$PRD"/connectivity/bvecs "$PRD"/connectivity/bvals \
          -datatype float32 -force
# lowb (not sure)
mrconvert "$PRD"/data/DWI/*_ecc_debiased_denoise_meanb0.nii.gz \
          "$PRD"/connectivity/lowb.mif \
          -datatype float32 -force
          #-fslgrad "$PRD"/connectivity/bvecs "$PRD"/connectivity/bvals \
# brain mask 
mrconvert "$PRD"/data/DWI/*_brain_mask.nii.gz \
          "$PRD"/connectivity/mask_native.mif -datatype float32 \
          -force

#rm -r "$PRD"/"$SUBJ_ID"/
