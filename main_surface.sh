#!/usr/bin/env bash

# TODO: add explicits echo for what to check in the figures
# TODO: nthreads
######## Checks and preset variables
# import config
while getopts ":c:" opt; do
     case $opt in
     c)
         export CONFIG=$OPTARG
         echo "use config file $CONFIG" >&2
         if [ ! -f $CONFIG ]
         then
         echo "config file unexistent" >&2
         exit 1
         fi
         source "$CONFIG"
         ;;
     \?)
         echo "Invalid option: -$OPTARG" >&2
         exit 1
         ;;
     :)
         echo "Option -$OPTARG requires an argument." >&2
         exit 1
         ;;
    esac
done

if [ ! -n "$CONFIG" ]
then
    echo "you must provide a config file"
    exit 1
fi

# set default variables config file
if [ ! -n $number_threads]
then
    if [ -f ~/.bashrc ] &&
    nb_threads=$(grep 'NumberOfThreads' ~/.bashrc | cut -f 2 -d " ")
    if [ "$nb_threads" = ""]
    then 
        echo "blah"
    fi
fi

if [ ! -n "$number_tracks" ]
then
    echo "config file not correct"
    exit 1
fi

# check FS bash variables
if [ ! -n "$SUBJECTS_DIR" ]
then
    echo "you have to set the SUBJECTS_DIR environnement
    variable for FreeSurfer"
    exit 1
else
    export FS=$SUBJECTS_DIR
fi

######### build cortical surface and region mapping
if [ ! -f $PRD/data/T1/T1.nii.gz ]
then
    echo "generating T1 from DICOM"
    mrconvert $PRD/data/T1/ $PRD/data/T1/T1.nii.gz
fi

###################### freesurfer
if [ ! -d $FS/$SUBJ_ID ] 
then
    echo "running recon-all of freesurfer"
    recon-all -i $PRD/data/T1/T1.nii.gz -s $SUBJ_ID -all
fi

###################################### left hemisphere
# export pial into text file
mkdir -p $PRD/surface
if [ ! -f $PRD/surface/lh.pial.asc ]
then
    echo "importing left pial surface from freesurfer"
    mris_convert $FS/$SUBJ_ID/surf/lh.pial $PRD/surface/lh.pial.asc
    # take care of the c_(ras) shift which is not done by FS (thks FS!)
    mris_info $FS/$SUBJ_ID/surf/lh.pial >& $PRD/surface/lhinfo.txt
fi

# triangles and vertices high
if [ ! -f $PRD/surface/lh_vertices_high.txt ]
then
    echo "extracting left vertices and triangles"
    python extract_high.py lh
fi

# decimation using brainvisa
if [ ! -f $PRD/surface/lh_vertices_low.txt ]
then
    echo "left decimation using remesher"
    # -> to mesh
    python txt2off.py $PRD/surface/lh_vertices_high.txt $PRD/surface/lh_triangles_high.txt $PRD/surface/lh_high.off
    #  decimation
    ./remesher/cmdremesher/cmdremesher $PRD/surface/lh_high.off $PRD/surface/lh_low.off
    # export to list vertices triangles
    python off2txt.py $PRD/surface/lh_low.off $PRD/surface/lh_vertices_low.txt $PRD/surface/lh_triangles_low.txt
fi

# create left the region mapping
if [ ! -f $PRD/surface/lh_region_mapping_low_not_corrected.txt ]
then
    echo "generating the left region mapping on the decimated surface"
    if [ -n "$matlab" ]
    then
        $matlab -r "rl='lh';run region_mapping.m; quit;" -nodesktop -nodisplay
    else
        sh region_mapping/distrib/run_region_mapping.sh $MCR
    fi
fi

# correct
if [ ! -f $PRD/surface/lh_region_mapping_low.txt ]
then
    echo "correct the left region mapping"
    python correct_region_mapping.py lh
    echo "check left region mapping"
    python check_region_mapping.py lh
fi

###################################### right hemisphere
# export pial into text file
if [ ! -f $PRD/surface/rh.pial.asc ]
then
    echo "importing right pial surface from freesurfer"
    mris_convert $FS/$SUBJ_ID/surf/rh.pial $PRD/surface/rh.pial.asc
    # take care of the c_(ras) shift which is not done by FS (thks FS!)
    mris_info $FS/$SUBJ_ID/surf/rh.pial >& $PRD/surface/rhinfo.txt
fi

# triangles and vertices high
if [ ! -f $PRD/surface/rh_vertices_high.txt ]
then
    echo "extracting right vertices and triangles"
    python extract_high.py rh
fi

# decimation using brainvisa
if [ ! -f $PRD/surface/rh_vertices_low.txt ]
then
    echo "right decimation using remesher"
    # -> to mesh
    python txt2off.py $PRD/surface/rh_vertices_high.txt $PRD/surface/rh_triangles_high.txt $PRD/surface/rh_high.off
    #  decimation
    ./remesher/cmdremesher/cmdremesher $PRD/surface/rh_high.off $PRD/surface/rh_low.off
    # export to list vertices triangles
    python off2txt.py $PRD/surface/rh_low.off $PRD/surface/rh_vertices_low.txt $PRD/surface/rh_triangles_low.txt
fi

if [ ! -f $PRD/surface/rh_region_mapping_low_not_corrected.txt ]
then
    echo "generating the right region mapping on the decimated surface"
    # create left the region mapping
    if [ -n "$matlab" ]
    then
        $matlab -r "rl='rh'; run region_mapping.m; quit;" -nodesktop -nodisplay
    else
        sh region_mapping/distrib/run_region_mapping.sh $MCR
    fi
fi

# correct
if [ ! -f $PRD/surface/rh_region_mapping_low.txt ]
then
    echo " correct the right region mapping"
    python correct_region_mapping.py rh
    echo "check right region mapping"
    python check_region_mapping.py rh
fi
###################################### both hemisphere
# prepare final directory
mkdir -p $PRD/$SUBJ_ID
mkdir -p $PRD/$SUBJ_ID/surface

# reunify both region_mapping, vertices and triangles
if [ ! -f $PRD/$SUBJ_ID/surface/region_mapping.txt ]
then
    echo "reunify both region mappings"
    python reunify_both_regions.py
fi

# zip to put in final format
pushd . > /dev/null
cd $PRD/$SUBJ_ID/surface > /dev/null
zip $PRD/$SUBJ_ID/surface.zip vertices.txt triangles.txt -q
cp region_mapping.txt ..
popd > /dev/null

########################### subcortical surfaces
# extract subcortical surfaces 
if [ ! -f $PRD/surface/subcortical/aseg_058_vert.txt ]
then
    echo "generating subcortical surfaces"
    ./aseg2srf -s $SUBJ_ID
    mkdir -p $PRD/surface/subcortical
    cp $FS/$SUBJ_ID/ascii/* $PRD/surface/subcortical
    python list_subcortical.py
fi

########################## build connectivity using mrtrix 3
mkdir -p $PRD/connectivity
mkdir -p $PRD/$SUBJ_ID/connectivity


## preprocessing
# See: http://mrtrix.readthedocs.io/en/0.3.16/workflows/DWI_preprocessing_for_quantitative_analysis.html

# TODO: add HCP data

# if single acquisition  with reversed directions
function mrchoose () {
    choice=$1
    shift
    $@ << EOF
$choice
EOF
}

# handle encoding scheme
if [ "$topup" = "reversed" ]
then
    echo "generate dwi mif file for use with reversed phase encoding"
    echo "(use of fsl topup)"
    # strides are arranged to make volume data contiguous in memory for
    # each voxel
    # float 32 to make data access faster in subsequent commands
    if [ ! -f $PRD/connectivity/predwi_1.mif ] || [ ! -f $PRD/connectivity/predwi_2.mif ]
    then # TODO: find a way for HCP dataset
         # TODO detect phase encoding automatically
         mrchoose 0 mrconvert $PRD/data/DWI/ $PRD/connectivity/predwi_1.mif \
                              -datatype float32 -stride 0,0,0,1 -force
         mrchoose 1 mrconvert $PRD/data/DWI/ $PRD/connectivity/predwi_2.mif \
                              -force -datatype float32 -stride 0,0,0,1 
        # check mif files
        if [ -n "$DISPLAY" ] && [ "$CHECK" = "yes" ]
        then
            echo "check predwi_*.mif files"
            mrview $PRD/connectivity/predwi_1.mif $PRD/connectivity/predwi_2.mif
        fi
    fi
    # recombining PE dir files 
    if [ ! -f $PRD/connectivity/predwi.mif ]
    then
        mrcat $PRD/connectivity/predwi_1.mif $PRD/connectivity/predwi_2.mif \
              $PRD/connectivity/predwi.mif -axis 3
        mrinfo $PRD/connectivity/predwi.mif \
               -export_grad_mrtrix $PRD/connectivity/bvecs_bvals_init \
               -export_pe_table $PRD/connectivity/pe_table -force 
    fi
else
    if [ ! -f $PRD/connectivity/predwi.mif ]
    then 
        echo "generate dwi mif file for use without topup (fsl)"
        mrconvert $PRD/data/DWI/ $PRD/connectivity/predwi.mif \
                  -export_pe_table $PRD/connectivity/pe_table \
                  -export_grad_mrtrix $PRD/connectivity/bvecs_bvals_init \
                  -datatype float32 -stride 0,0,0,1 -force
        # check mif file
        if [ -n "$DISPLAY" ] && [ "$CHECK" = "yes" ]
        then
            echo "check predwi_*.mif file"
            mrview $PRD/connectivity/predwi.mif 
        fi
    fi
fi

# denoising the volumes
if [ ! -f $PRD/connectivity/predwi_denoised.mif ]
then # denoising the combined-directions file is preferable to denoising \
     # predwi1 and 2 separately because of a higher no of volumes
    echo "denoising dwi data"
    dwidenoise $PRD/connectivity/predwi.mif \
               $PRD/connectivity/predwi_denoised.mif \
               -noise $PRD/connectivity/noise.mif -force
    if [ ! -f $PRD/connectivity/noise_res.mif ]
    then # calculate residuals noise
        mrcalc $PRD/connectivity/predwi.mif \
               $PRD/connectivity/predwi_denoised.mif \
               -subtract $PRD/connectivity/noise_res.mif
        # check noise file: lack of anatomy is a marker of accuracy
        if [ -n "$DISPLAY" ] && [ "$CHECK" = "yes" ]
        then # noise.mif can also be used for SNR calculation
            echo "check noise/predwi_*_denoised.mif files"
            mrview $PRD/connectivity/predwi.mif \
                   $PRD/connectivity/predwi_denoised.mif \
                   $PRD/connectivity/noise.mif \
                   $PRD/connectivity/noise_res.mif  
        fi
    fi
fi

# topup/eddy corrections
if [ ! -f $PRD/connectivity/predwi_denoised_preproc.mif ]
then
    if [ "$topup" = "reversed" ] || [ "$topup" = "eddy_correct" ]
    then # eddy maybe topup corrections depending of the encoding scheme
        echo "apply eddy and maybe topup"
        dwipreproc $PRD/connectivity/predwi_denoised.mif \
                   $PRD/connectivity/predwi_denoised_preproc.mif \
                   -export_grad_mrtrix $PRD/connectivity/bvecs_bvals_final \
                   -rpe_header -eddy_options ' --repol' -cuda -force    
        if [ -n "$DISPLAY" ] && [ "$CHECK" = "yes" ]
        then
            echo "check topup/eddy preprocessed mif file"
            mrview $PRD/connectivity/predwi.mif \
                   $PRD/connectivity/predwi_denoised.mif \
                   $PRD/connectivity/predwi_denoised_preproc.mif 
        fi
    else # no topup/eddy
        echo "no topup/eddy applied"
        mrconvert $PRD/connectivity/predwi_denoised.mif \
                  $PRD/connectivity/predwi_denoised_preproc.mif \
                  -export_grad_mrtrix $PRD/connectivity/bvecs_bvals_final -force
        # check preproc files
        if [ -n "$DISPLAY" ] && [ "$CHECK" = "yes" ]
        then
            echo "check preprocessed mif file (no topup/no eddy)"
            mrview $PRD/connectivity/predwi.mif \
                   $PRD/connectivity/predwi_denoised.mif \
                   $PRD/connectivity/predwi_denoised_preproc.mif 
        fi
    fi
fi

# Native-resolution mask creation
if [ ! -f $PRD/connectivity/mask_native.mif ]
then
    echo "create dwi mask"
    dwi2mask $PRD/connectivity/predwi_denoised_preproc.mif \
             $PRD/connectivity/mask_native.mif
    # check mask file
    if [ -n "$DISPLAY" ] && [ "$CHECK" = "yes" ]
    then
        echo "check native mask mif file"
        mrview $PRD/connectivity/predwi_denoised_preproc.mif \
               -overlay.load $PRD/connectivity/mask_native.mif \
               -overlay.opacity 0.5
    fi
fi

# Bias field correction
if [ ! -f $PRD/connectivity/predwi_denoised_preproc_bias.mif ]
then
    # ANTS seems better than FSL
    # see http://mrtrix.readthedocs.io/en/0.3.16/workflows/DWI_preprocessing_for_quantitative_analysis.html
    if [ -n "$ANTSPATH" ]
    then
        echo "bias correct using ANTS"
        dwibiascorrect $PRD/connectivity/predwi_denoised_preproc.mif \
                       $PRD/connectivity/predwi_denoised_preproc_bias.mif \
                       -mask $PRD/connectivity/mask_native.mif \
                       -bias $PRD/connectivity/B1_bias.mif -ants -force
    else
        echo "bias correct using FSL"
        dwibiascorrect $PRD/connectivity/predwi_denoised_preproc.mif \
                       $PRD/connectivity/predwi_denoised_preproc_bias.mif \
                       -mask $PRD/connectivity/mask_native.mif \
                       -bias $PRD/connectivity/B1_bias.mif -fsl -force
    fi
fi

# TOCHECK
# upsampling and reorienting a la fsl
# reorienting means -stride -1,+2,+3,+4; upsampling 
# (Dyrby TB. Neuroimage. 2014 Dec;103:202-13.) can help
# registration with structural and is common with mrtrix3 fixel analysis pipeline
if [ ! -f $PRD/connectivity/dwi.mif ]
then
    echo "upsample dwi"
    mrresize $PRD/connectivity/predwi_denoised_preproc_bias.mif -  -scale 2 | \
    mrconvert - -force -datatype float32 -stride -1,+2,+3,+4 $PRD/connectivity/dwi.mif
##   -interp default: cubic
fi

if [ ! -f $PRD/connectivity/mask.mif ]
then
    echo "upsample mask"
    mrresize -force -scale 2 $PRD/connectivity/mask_native.mif - | \
    mrconvert - $PRD/connectivity/mask.mif -datatype bit -stride -1,+2,+3 -force
    maskfilter $PRD/connectivity/mask.mif dilate \
               $PRD/connectivity/mask_dilated.mif -force -npass 2 
  # for dwi2fod step, a permissive, dilated mask can be used to minimize
  # streamline premature termination, see BIDS protocol
    # check upsampled files
    if [ -n "$DISPLAY" ] && [ "$CHECK" = "yes" ]
    then
        echo "check upsampled mif files"
        mrview $PRD/connectivity/dwi.mif \
               -overlay.load $PRD/connectivity/mask.mif \
               -overlay.load $PRD/connectivity/mask_dilated.mif \
               -overlay.opacity 0.5 -norealign 
    fi
fi

## FLIRT registration
# low b extraction to FSL
if [ ! -f $PRD/connectivity/lowb.nii.gz ]
then
    echo "extracting b0 vols for registration"
    dwiextract $PRD/connectivity/dwi.mif $PRD/connectivity/lowb.mif \
               -bzero -force 
    # stride from mrtrix to FSL, RAS to LAS
    # see: http://mrtrix.readthedocs.io/en/latest/getting_started/image_data.html
    mrconvert $PRD/connectivity/lowb.mif $PRD/connectivity/lowb.nii.gz \
              -stride -1,+2,+3,+4
    # for visualization 
    mrmath  $PRD/connectivity/lowb.mif mean $PRD/connectivity/meanlowb.mif \
            -axis 3 -force
fi

# generating FSl brain.mgz
if [ ! -f $PRD/connectivity/brain.nii.gz ]
then # brain.mgz seems to be superior to diff to T1
     # as BET stripping is unfortunate in many situations, 
     # and FS pial eddited volumes already present
     # TODO: ref? T1 option?
     # stride from FS to FSL: RAS to LAS
     # see: http://www.grahamwideman.com/gw/brain/fs/coords/fscoords.htm
    echo "generating FSL orientation for masked brain"
    mrconvert $FS/$SUBJ_ID/mri/brain.mgz $PRD/connectivity/brain.nii.gz \
              -datatype float32 -stride -1,+2,+3,+4 -force 
fi

# TODO
## Generate transform image (dwi) for alternative registration method: replace lowb.nii.gz with output lowb_pseudobrain.nii.gz in the subsequent registration steps
##    if [ ! -f $PRD/connectivity/lowb_pseudobrain.nii.gz ]
##    then
##        echo "extracting b0 vols for registration: pseudostructural"
##        dwiextract $PRD/connectivity/dwi.mif -bzero - | mrmath - mean - -axis 3 | mrcalc 1 - -divide $PRD/connectivity/mask_upsampled.mif -multiply - | mrconvert - - -stride -1,+2,+3 | mrhistmatch - $PRD/connectivity/brain.nii.gz $PRD/connectivity/lowb_pseudobrain.nii.gz
##        if [ -n "$DISPLAY" ] && [ "$CHECK" = "yes" ]
##        then
##            echo "check pseudo lowb files"
##            mrview $PRD/connectivity/lowb_pseudobrain.nii.gz $PRD/connectivity/lowb.nii.gz -overlay.load $PRD/connectivity/lowb_pseudobrain.nii.gz -overlay.opacity 0.5 -norealign
##        fi
##    fi

# aparc+aseg to FSL
if [ ! -f $PRD/connectivity/aparc+aseg.nii.gz ]
then
    echo "generating FSL orientation for aparc+aseg"
    # stride from FS to FSL: RAS to LAS
    mrconvert $FS/$SUBJ_ID/mri/aparc+aseg.mgz \
              $PRD/connectivity/aparc+aseg.nii.gz -stride -1,+2,+3,+4 
fi

# check orientations
if [ ! -f $PRD/connectivity/aparc+aseg_reorient.nii.gz ]
then
    echo "reorienting the region parcellation"
    fslreorient2std $PRD/connectivity/aparc+aseg.nii.gz \
                    $PRD/connectivity/aparc+aseg_reorient.nii.gz
    # check parcellation to brain.mgz
    if [ -n "$DISPLAY" ] && [ "$CHECK" = "yes" ]
    then
        echo "check parcellation"
        echo "if it's correct, just close the window." 
        echo "Otherwise... well, it should be correct anyway"
        mrview $PRD/connectivity/brain.nii.gz \
               -overlay.load $PRD/connectivity/aparc+aseg_reorient.nii.gz \
               -overlay.opacity 0.5 -norealign
    fi
fi

# aparcaseg to diff by inverser transform
if [ ! -f $PRD/connectivity/aparcaseg_2_diff.nii.gz ]
then # TOCHECK:6 dof vs 12 dof
    echo "register aparc+aseg to diff"
    "$FSL"flirt -in $PRD/connectivity/lowb.nii.gz \
                -ref $PRD/connectivity/brain.nii.gz \
                -omat $PRD/connectivity/diffusion_2_struct.mat \
                -out $PRD/connectivity/lowb_2_struct.nii.gz -dof 6 \
                -searchrx -180 180 -searchry -180 180 -searchrz -180 180 \
                -cost mutualinfo
    transformconvert $PRD/connectivity/diffusion_2_struct.mat \
                     $PRD/connectivity/lowb.nii.gz \
                     $PRD/connectivity/brain.nii.gz \
                     flirt_import $PRD/connectivity/diffusion_2_struct_mrtrix.txt \
                      -force 
    #TOCHECK: syntax
    mrtransform $PRD/connectivity/aparc+aseg_reorient.nii.gz \
                $PRD/connectivity/aparcaseg_2_diff.nii.gz \
                -linear $PRD/connectivity/diffusion_2_struct_mrtrix.txt \
                -inverse -datatype uint32 -force 
#    mrtransform -force -linear $PRD/connectivity/diffusion_2_struct_mrtrix.txt -inverse $PRD/connectivity/aparc+aseg_reorient.nii.gz -datatype uint32 $PRD/connectivity/aparcaseg_2_diff.nii.gz  
fi

# brain to diff by inverse transform
if [ ! -f $PRD/connectivity/brain_2_diff.nii.gz ]
then
    echo "register brain to diff"
    mrtransform $PRD/connectivity/brain.nii.gz \
                $PRD/connectivity/brain_2_diff.nii.gz \
                -linear $PRD/connectivity/diffusion_2_struct_mrtrix.txt \
                -inverse -force 

    # check parcellation to diff
    if [ -n "$DISPLAY" ]  && [ "$CHECK" = "yes" ]
    then
        echo "check parcellation registration to diffusion space"
        echo "if it's correct, just close the window."
        echo "Otherwise you will have to do the registration by hand"
        mrview $PRD/connectivity/brain_2_diff.nii.gz \
               $PRD/connectivity/lowb.nii.gz \
               -overlay.load $PRD/connectivity/aparcaseg_2_diff.nii.gz \
               -overlay.opacity 0.5 -norealign
    fi
fi


# prepare file for act
if [ "$act" = "yes" ] && [ ! -f $PRD/connectivity/act.mif ]
then
    echo "prepare files for act"
    5ttgen fsl $PRD/connectivity/brain_2_diff.nii.gz $PRD/connectivity/act.mif \
           -premasked -force       
    if [ -n "$DISPLAY" ]  && [ "$CHECK" = "yes" ]
    then
        echo "check tissue segmented image"
        5tt2vis -force $PRD/connectivity/act.mif $PRD/connectivity/act_vis.mif
        mrview $PRD/connectivity/act_vis.mif
    fi
fi

# Response function estimation
# Check if multi or single shell
shells=$(mrinfo -shells $PRD/connectivity/dwi.mif)
echo "shell b values are $shells"
nshells=($shells)
no_shells=${#nshells[@]}
echo "no of shells are $no_shells"

if [ "$no_shells" -gt 2 ] 
then
# Multishell
    if [ ! -f $PRD/connectivity/response_wm.txt ] 
    then
        if [ "$act" = "yes" ]
        then 
            echo "estimating response using msmt algorithm"
            dwi2response msmt_5tt $PRD/connectivity/dwi.mif \
                         $PRD/connectivity/act.mif \
                         $PRD/connectivity/response_wm.txt \
                         $PRD/connectivity/response_gm.txt \
                         $PRD/connectivity/response_csf.txt \
                         -voxels $PRD/connectivity/RF_voxels.mif \
                         -mask $PRD/connectivity/mask.mif -force
            if [ -n "$DISPLAY" ]  && [ "$CHECK" = "yes" ]
            then
                echo "check ODF image"
                mrview $PRD/connectivity/meanlowb.mif \
                       -overlay.load $PRD/connectivity/RF_voxels.mif \
                       -overlay.opacity 0.5
            fi
        else
            echo "estimating response using dhollander algorithm"
            dwi2response dhollander $PRD/connectivity/dwi.mif \
                         $PRD/connectivity/response_wm.txt \
                         $PRD/connectivity/response_gm.txt \
                         $PRD/connectivity/response_csf.txt \
                         -voxels $PRD/connectivity/RF_voxels.mif \
                         -mask $PRD/connectivity/mask.mif -force 
        fi
    fi
else
# Single shell only
    if [ ! -f $PRD/connectivity/response_wm.txt ]
    then
        echo "estimating response using dhollander algorithm"
        # dwi2response tournier $PRD/connectivity/dwi.mif $PRD/connectivity/response.txt -force -voxels $PRD/connectivity/RF_voxels.mif -mask $PRD/connectivity/mask.mif
        dwi2response dhollander $PRD/connectivity/dwi.mif \
                     $PRD/connectivity/response_wm.txt \
                     $PRD/connectivity/response_gm.txt \
                     $PRD/connectivity/response_csf.txt \
                     -voxels $PRD/connectivity/RF_voxels.mif \
                     -mask $PRD/connectivity/mask.mif -force 
        if [ -n "$DISPLAY" ]  && [ "$CHECK" = "yes" ]
        then
            echo "check ODF image"
            mrview $PRD/connectivity/meanlowb.mif \
                   -overlay.load $PRD/connectivity/RF_voxels.mif \
                   -overlay.opacity 0.5
        fi
    fi
fi

# Fibre orientation distribution estimation
if [ ! -f $PRD/connectivity/wm_CSD$lmax.mif ]
then # Both for multishell and single shell since we use dhollander in the 
     # single shell case
     # see: http://community.mrtrix.org/t/wm-odf-and-response-function-with-dhollander-option---single-shell-versus-multi-shell/572/4
    echo "calculating fod on multishell data"
    dwi2fod msmt_csd $PRD/connectivity/dwi.mif \
            $PRD/connectivity/response_wm.txt \
            $PRD/connectivity/wm_CSD$lmax.mif \
            $PRD/connectivity/response_gm.txt \
            $PRD/connectivity/gm_CSD$lmax.mif \
            $PRD/connectivity/response_csf.txt \
            $PRD/connectivity/csf_CSD$lmax.mif \
            -mask $PRD/connectivity/mask_dilated.mif -force 

    if [ -n "$DISPLAY" ]  && [ "$CHECK" = "yes" ]
    then
        echo "check ODF image"
        mrconvert $PRD/connectivity/wm_CSD$lmax.mif - -coord 3 0 \
        | mrcat $PRD/connectivity/csf_CSD$lmax.mif \
                $PRD/connectivity/gm_CSD$lmax.mif - \
                $PRD/connectivity/tissueRGB.mif -axis 3
        mrview $PRD/connectivity/tissueRGB.mif \
               -odf.load_sh $PRD/connectivity/wm_CSD$lmax.mif 
    fi
fi

# tractography
if [ ! -f $PRD/connectivity/whole_brain.tck ]
then
    if [ "sift" = "sift"]
    then
        if [ -n "$sift_multiplier"]
        then
            sift_multiplier=10
        fi
        number_tracks=$(($number_tracks*$sift_multiplier))
    fi
    # TODO: check float operations bash
    native_voxelsize=$(mrinfo $PRD/connectivity/mask_native.mif -vox \
                     | cut -f 1 -d " " | xargs printf "%1.f")
    stepsize=$(($native_voxelsize/2))
    angle=$((90*$stepsize/$native_voxelsize))
    if [ "$act" = "yes" ]
    then
        echo "generating tracks using act"

        if [ "$seed" = "gmwmi" ]
        then
            echo "seeding from gmwmi" 
            5tt2gmwmi $PRD/connectivity/act.mif \
                      $PRD/connectivity/gmwmi_mask.mif -force 
            # TODO: cutoff add not msmt csd back to default?
            # TODO: min length check andreas paper
            tckgen $PRD/connectivity/wm_CSD"$lmax".mif \
                   $PRD/connectivity/whole_brain.tck \
                   -seed_gmwmi $PRD/connectivity/gmwmi_mask.mif 
                   -act $PRD/connectivity/act.mif -select "$number_tracks" \
                   -seed_unidirectional -crop_at_gmwmi -backtrack \
                   -minlength 4 -maxlength 250 -step "$stepsize" -angle "$angle" \
                   -cutoff 0.06 -force
        else # [ "$seed" = "dynamic" ] default. 
             # -dynamic seeding may work slightly better than gmwmi, 
             # see Smith RE Neuroimage. 2015 Oct 1;119:338-51.
            echo "seeding dynamically"   
            tckgen $PRD/connectivity/wm_CSD"$lmax".mif \
                   $PRD/connectivity/whole_brain.tck \
                   -seed_dynamic $PRD/connectivity/wm_CSD$lmax.mif \
                   -act $PRD/connectivity/act.mif -select "$number_tracks" \
                   -crop_at_gmwmi -backtrack -minlength 4 -maxlength 250 \
                   -step "$stepsize" -angle "$angle" -cutoff 0.06 -force 
        fi  
    else
        echo "generating tracks without using act" 
        echo "seeding dynamically" 
        tckgen $PRD/connectivity/wm_CSD"$lmax".mif \
               $PRD/connectivity/whole_brain.tck \
               -seed_dynamic $PRD/connectivity/wm_CSD"$lmax".mif \
               -mask $PRD/connectivity/mask.mif -select "$number_tracks" \
               -maxlength 250 -step "$stepsize" -angle "$angle" -cutoff 1  -force 
    fi
fi

# postprocessing
if [ ! -f $PRD/connectivity/whole_brain_post.tck ]
then
    if [ "$sift" = "sift"]
    then
        echo "using sift"
        number_tracks=$(($number_tracks/$sift_multiplier))
        if [ "$act" = "yes" ] 
        then
            echo "trimming tracks using sift/act" 
            tcksift $PRD/connectivity/whole_brain.tck \
                    $PRD/connectivity/wm_CSD"$lmax".mif \
                    $PRD/connectivity/whole_brain_post.tck \
                    -act $PRD/connectivity/act.mif \
                    -out_mu $PRD/connectivity/mu.txt \
                    -term_number $number_tracks -fd_scale_gm -force

        else
            echo "trimming tracks using sift/without act" 
            tcksift $PRD/connectivity/whole_brain.tck \
                    $PRD/connectivity/wm_CSD"$lmax".mif \
                    $PRD/connectivity/whole_brain_post.tck \
                    -out_mu $PRD/connectivity/mu.txt \
                    -term_number $number_tracks -force
        fi
    if [ "$sift" = "sift2" ] 
    then 
        echo "running sift2"
        ln -s $PRD/connectivity/whole_brain.tck $PRD/connectivity/whole_brain_post.tck
        if [ "$act" = "yes" ]
        then
            echo "using act" 
            tcksift2 $PRD/connectivity/whole_brain.tck \
                     $PRD/connectivity/wm_CSD"$lmax".mif \
                     $PRD/connectivity/streamline_weights.csv\
                     -act $PRD/connectivity/act.mif \
                     -out_mu $PRD/connectivity/mu.txt \
                     -out_coeffs $PRD/connectivity/streamline_coeffs.csv \
                     -fd_scale_gm -force
        else
            tcksift2 $PRD/connectivity/whole_brain.tck \
                     $PRD/connectivity/wm_CSD"$lmax".mif \
                     $PRD/connectivity/streamline_weights.csv \
                     -out_mu $PRD/connectivity/mu.txt \
                     -out_coeffs $PRD/connectivity/streamline_coeffs.csv -force
        fi
    else 
        echo "not using sift2"
        ln -s $PRD/connectivity/whole_brain.tck \
              $PRD/connectivity/whole_brain_post.tck
    fi
fi

## now compute connectivity and length matrix
if [ ! -f $PRD/connectivity/aparcaseg_2_diff.mif ]
then
    echo " compute FS labels"
    labelconvert $PRD/connectivity/aparcaseg_2_diff.nii.gz \
                 $FREESURFER_HOME/FreeSurferColorLUT.txt \
                 fs_region.txt $PRD/connectivity/aparcaseg_2_diff_fs.mif -force
    if [ "$aseg" = "fsl" ]
    then # FS derived subcortical parcellation is too variable and prone to 
        # errors => labelsgmfix) was generated, 
        # see Smith RE Neuroimage. 2015 Jan 1;104:253-65.
        # TODO: check effect on region mapping
        # TODO; -sgm_amyg_hipp option to consider
        echo "fix FS subcortical labels to generate FSL labels"
        labelsgmfix $PRD/connectivity/aparcaseg_2_diff_fs.mif \
                    $PRD/connectivity/brain_2_diff.nii.gz fs_region.txt \
                    $PRD/connectivity/aparcaseg_2_diff_fsl.mif -premasked -force   
    fi 
fi

if [ ! -f $PRD/connectivity/weights.csv ]
then
    echo "compute connectivity matrix weights"
    if [ "$sift" = "sift2" ]
    then # -tck_weights_in flag only needed for sift2 but not for sift/no processing
         # TOCHECK:  mrtrix3 currently generates upper_triangular weights 
         # matrices, need to add -symmetric flag if needed, also -zero_diagonal 
         # if needed (did not see that in the original code)
         # I think I do the symmetric in the compute_connectivity files.py
         # diagonal we want to keep it
        tck2connectome $PRD/connectivity/whole_brain_post.tck \
                       $PRD/connectivity/aparcaseg_2_diff_$aseg.mif \
                       $PRD/connectivity/weights.csv -assignment_radial_search 2 \
                       -out_assignments $PRD/connectivity/edges_2_nodes.csv \
                       -tck_weights_in $PRD/connectivity/streamline_weights.csv \
                       -force
    else
        tck2connectome $PRD/connectivity/whole_brain_post.tck \
                       $PRD/connectivity/aparcaseg_2_diff_$aseg.mif \
                       $PRD/connectivity/weights.csv -assignment_radial_search 2 \
                       -out_assignments $PRD/connectivity/edges_2_nodes.csv \
                       -force  
    fi
fi

if [ ! -f $PRD/connectivity/tract_lengths.csv ]
then
    echo "compute connectivity matrix edge lengths"
    if [ "$sift" = "sift2" ]
    then # TOCHECK: the formed -metric meanlength adaptation: if the mean edge 
         # length is needed to estimate internode conduction delays, my take on 
         # the new version tck2connectome is that default (-stat_edge sum) would
         # sum up the no of streamlines between two nodes; simply changing it to
         # (-stat_edge mean) would generate a 0,1 binary matrix (which happened 
         # during testing), so streamlines need to be adjusted by their length 
         # before their mean is calculated (still, needs to be verified); need 
         # to be careful when applying sift2, as here the mean is 
         # sum(streamline length * streamline weight)/no streamlines, a bit more
         # fuzzy to interpret than with sift, however left it as option
       tck2connectome $PRD/connectivity/whole_brain_post.tck \
                      $PRD/connectivity/aparcaseg_2_diff_$aseg.mif \
                      $PRD/connectivity/tract_lengths.csv \
                      -tck_weights_in $PRD/connectivity/streamline_weights.csv \
                      -assignment_radial_search 2 -zero_diagonal -scale_length \
                      -stat_edge mean -force 
    else
       tck2connectome $PRD/connectivity/whole_brain_post.tck \
                      $PRD/connectivity/aparcaseg_2_diff_$aseg.mif \
                      $PRD/connectivity/tract_lengths.csv \
                      -assignment_radial_search 2 -zero_diagonal -scale_length \
                      -stat_edge mean -force
    fi
fi

# view connectome
if [ -n "$DISPLAY" ] && [ "$CHECK" = "yes" ]
then
    echo "view connectome edges as lines or streamlines"
    if [ ! -f $PRD/connectivity/exemplars.tck ]
    then
        if [ "$sift" = "sift2" ]
        then
            connectome2tck $PRD/connectivity/whole_brain_post.tck \
                           $PRD/connectivity/edges_2_nodes.csv \
                           $PRD/connectivity/exemplars.tck \
                           -exemplars $PRD/connectivity/aparcaseg_2_diff_$aseg.mif \
                           -tck_weights_in $PRD/connectivity/streamline_weights.csv \
                           -files single 
        else 
            connectome2tck $PRD/connectivity/whole_brain_post.tck \
                           $PRD/connectivity/edges_2_nodes.csv \
                           $PRD/connectivity/exemplars.tck \
                           -exemplars $PRD/connectivity/aparcaseg_2_diff_$aseg.mif \
                           -files single 
        fi
    fi
    # TOCHECK: in mrview, load the lut table (fs_region.txt) for node correspondence, 
    # and exemplars.tck if wanting to see edges as streamlines 
    mrview $PRD/connectivity/aparcaseg_2_diff_$aseg.mif \
           -connectome.init $PRD/connectivity/aparcaseg_2_diff_$aseg.mif \
           -connectome.load $PRD/connectivity/weights.csv 
fi

# view tractogram and tdi
if [ -n "$DISPLAY" ] && [ "$CHECK" = "yes" ]
then
    echo "view tractogram and tdi image"
    if [ ! -f $PRD/connectivity/whole_brain_post_decimated.tck ]
    then # $(( number_tracks/100)) this follows some recommendations by 
         # JD Tournier to avoid mrview to be to slow
         # (for visualization no more than 100-200K streamlines)
         # => min(100k, number_tracks/100)
        if [ "$sift" = "sift2" ]
        then
            tckedit $PRD/connectivity/whole_brain_post.tck \
                    $PRD/connectivity/whole_brain_post_decimated.tck \
                    -tck_weights_in $PRD/connectivity/streamline_weights.csv 
                    -number $(($number_tracks<100000?$number_tracks:100000))
                    -minweight 1 -force 
        else 
            tckedit $PRD/connectivity/whole_brain_post.tck \
                    $PRD/connectivity/whole_brain_post_decimated.tck \
                    -number $(($number_tracks<100000?$number_tracks:100000)) \
                    -force  
        fi  
    fi
    if [ ! -f $PRD/connectivity/whole_brain_post_tdi.mif ]
    then
        if [ "$sift" = "sift2" ]
        then
            tckmap $PRD/connectivity/whole_brain_post.tck \
                   $PRD/connectivity/whole_brain_post_tdi.mif \
                   -tck_weights_in $PRD/connectivity/streamline_weights.csv \
                   -dec -vox 1 -force 
        else
            tckmap $PRD/connectivity/whole_brain_post.tck \
                   $PRD/connectivity/whole_brain_post_tdi.mif \
                   -dec -vox 1 -force
        fi 
    fi
    mrview $PRD/connectivity/aparcaseg_2_diff_$aseg.mif \
           -overlay.load $PRD/connectivity/whole_brain_post_tdi.mif \
           -overlay.opacity 0.5 -overlay.interpolation_off \
           -tractography.load $PRD/connectivity/whole_brain_post_decimated.tck 
fi


# Compute other files
# we do not compute hemisphere
# subcortical is already done
cp cortical.txt $PRD/$SUBJ_ID/connectivity/cortical.txt

# compute centers, areas and orientations
if [ ! -f $PRD/$SUBJ_ID/connectivity/weights.txt ]
then
    echo " generate useful files for TVB"
    python compute_connectivity_files.py
fi

# zip to put in final format
pushd . > /dev/null
cd $PRD/$SUBJ_ID/connectivity > /dev/null
zip $PRD/$SUBJ_ID/connectivity.zip areas.txt average_orientations.txt \
    weights.txt tract_lengths.txt cortical.txt centres.txt -q
popd > /dev/null 



# Done 
read -p "Press [Enter] key to continue..." 

# TODO : update sub parcellations
###################################################
# compute sub parcellations connectivity if asked
if [ -n "$K_list" ]
then
    for K in $K_list
    do
        export curr_K=$(( 2**K ))
        mkdir -p $PRD/$SUBJ_ID/connectivity_"$curr_K"

        if [ -n "$matlab" ]  
        then
            if [ ! -f $PRD/connectivity/aparcaseg_2_diff_"$curr_K".nii.gz ]
            then
            $matlab -r "run subparcel.m; quit;" -nodesktop -nodisplay 
            gzip $PRD/connectivity/aparcaseg_2_diff_"$curr_K".nii
            fi
        else
            if [ ! -f $PRD/connectivity/aparcaseg_2_diff_"$curr_K".nii.gz ]
            then
            sh subparcel/distrib/run_subparcel.sh $MCR  
            gzip $PRD/connectivity/aparcaseg_2_diff_"$curr_K".nii
            fi
        fi

        if [ ! -f $PRD/connectivity/aparcaseg_2_diff_"$curr_K".mif ]
        then
            labelconfig $PRD/connectivity/aparcaseg_2_diff_"$curr_K".nii.gz $PRD/connectivity/corr_mat_"$curr_K".txt $PRD/connectivity/aparcaseg_2_diff_"$curr_K".mif  -lut_basic $PRD/connectivity/corr_mat_"$curr_K".txt
        fi

        if [ ! -f $PRD/connectivity/weights_$curr_K.csv ]
        then
            echo "compute connectivity sub matrix using act"
            tck2connectome $PRD/connectivity/whole_brain_post.tck $PRD/connectivity/aparcaseg_2_diff_"$curr_K".mif $PRD/connectivity/weights_"$curr_K".csv -assignment_radial_search 2
            tck2connectome  $PRD/connectivity/whole_brain_post.tck $PRD/connectivity/aparcaseg_2_diff_"$curr_K".mif $PRD/connectivity/tract_lengths_"$curr_K".csv -metric meanlength -assignment_radial_search 2 -zero_diagonal 
        fi

        if [ ! -f $PRD/$SUBJ_ID/connectivity_"$curr_K"/weights.txt ]
        then
            echo "generate files for TVB subparcellations"
            python compute_connectivity_sub.py $PRD/connectivity/weights_"$curr_K".csv $PRD/connectivity/tract_lengths_"$curr_K".csv $PRD/$SUBJ_ID/connectivity_"$curr_K"/weights.txt $PRD/$SUBJ_ID/connectivity_"$curr_K"/tract_lengths.txt
        fi

        pushd . > /dev/null
        cd $PRD/$SUBJ_ID/connectivity_"$curr_K" > /dev/null
        zip $PRD/$SUBJ_ID/connectivity_"$curr_K".zip weights.txt tract_lengths.txt centres.txt average_orientations.txt -q 
        popd > /dev/null
    done
fi

######################## compute MEG and EEG forward projection matrices
# make BEM surfaces
if [ ! -h ${FS}/${SUBJ_ID}/bem/inner_skull.surf ]
then
    echo "generating bem surfaces"
    mne_watershed_bem --subject ${SUBJ_ID}
    ln -s ${FS}/${SUBJ_ID}/bem/watershed/${SUBJ_ID}_inner_skull_surface ${FS}/${SUBJ_ID}/bem/inner_skull.surf
    ln -s ${FS}/${SUBJ_ID}/bem/watershed/${SUBJ_ID}_outer_skin_surface  ${FS}/${SUBJ_ID}/bem/outer_skin.surf
    ln -s ${FS}/${SUBJ_ID}/bem/watershed/${SUBJ_ID}_outer_skull_surface ${FS}/${SUBJ_ID}/bem/outer_skull.surf
fi

# export to ascii
if [ ! -f ${FS}/${SUBJ_ID}/bem/inner_skull.asc ]
then
    echo "importing bem surface from freesurfer"
    mris_convert $FS/$SUBJ_ID/bem/inner_skull.surf $FS/$SUBJ_ID/bem/inner_skull.asc
    mris_convert $FS/$SUBJ_ID/bem/outer_skull.surf $FS/$SUBJ_ID/bem/outer_skull.asc
    mris_convert $FS/$SUBJ_ID/bem/outer_skin.surf $FS/$SUBJ_ID/bem/outer_skin.asc
fi

# triangles and vertices bem
if [ ! -f $PRD/$SUBJ_ID/surface/inner_skull_vertices.txt ]
then
    echo "extracting bem vertices and triangles"
    python extract_bem.py inner_skull 
    python extract_bem.py outer_skull 
    python extract_bem.py outer_skin 
fi

if [ ! -f ${FS}/${SUBJ_ID}/bem/${SUBJ_ID}-head.fif ]
then
    echo "generating head bem"
    mkheadsurf -s $SUBJ_ID
    mne_surf2bem --surf ${FS}/${SUBJ_ID}/surf/lh.seghead --id 4 --check --fif ${FS}/${SUBJ_ID}/bem/${SUBJ_ID}-head.fif 
fi

if [ -n "$DISPLAY" ] && [ "$CHECK" = "yes" ]
then
    echo "check bem surfaces"
    freeview -v ${FS}/${SUBJ_ID}/mri/T1.mgz -f ${FS}/${SUBJ_ID}/bem/inner_skull.surf:color=yellow:edgecolor=yellow ${FS}/${SUBJ_ID}/bem/outer_skull.surf:color=blue:edgecolor=blue ${FS}/${SUBJ_ID}/bem/outer_skin.surf:color=red:edgecolor=red
fi

# Setup BEM
if [ ! -f ${FS}/${SUBJ_ID}/bem/*-bem.fif ]
then
    worked=0
    outershift=0
    while [ "$worked" == 0 ]
    do
        echo "try generate forward model with 0 shift"
        worked=1
        mne_setup_forward_model --subject ${SUBJ_ID} --surf --ico 4 --outershift $outershift || worked=0 
        if [ "$worked" == 0 ]
        then
            echo "try generate foward model with 1 shift"
            worked=1
            mne_setup_forward_model --subject ${SUBJ_ID} --surf --ico 4 --outershift 1 || worked=0 
        fi
        if [ "$worked" == 0 ] && [ "$CHECK" = "yes" ]
        then
            echo 'you can try using a different shifting value for outer skull, please enter a value in mm'
            read outershift;
            echo $outershift
        elif [ "$worked" == 0 ]
        then
            echo "bem did not worked"
            worked=1
        elif [ "$worked" == 1 ]
        then
            echo "success!"
        fi
    done
fi

