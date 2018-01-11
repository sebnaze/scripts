# check mandatory variables
if [ -z "$PRD" ]; then
  echo "PRD path missing"
  exit 1
fi

if [ -z "$SUBJ_ID" ]; then
  echo "SUBJ_ID path missing"
  exit 1
fi

if [ -z "$MATLAB" ] && [ -z "$MCR"]; then
  echo "matlab or MCR path missing"
  exit 1
fi

if [ -z "$SUBJECTS_DIR" ]; then
  echo "you have to set the SUBJECTS_DIR environnement variable for FreeSurfer" >> "$PRD"/log_processing_parameters.txt
  exit 1
else
    export FS="$SUBJECTS_DIR"
fi

# set default parameters if not set in config file
echo "##### $( date ) #####" | tee -a "$PRD"/log_processing_parameters.txt

if [ -z "$FSL" ] || [ "$FSL" != "fsl5.0" ]; then
  echo "set FSL parameter to empty" | tee -a "$PRD"/log_processing_parameters.txt
  FSL=""
else
  echo "FSL parameter is "$FSL"" | tee -a "$PRD"/log_processing_parameters.txt
fi

if [ -z "$HCP" ] || [ "$HCP" != "no" -a "$HCP" != "yes" ]; then
  echo "set HCP parameter to no" | tee -a "$PRD"/log_processing_parameters.txt
  HCP="no"
else
  echo "HCP parameter is "$HCP"" | tee -a "$PRD"/log_processing_parameters.txt
fi

if [ -z "$CHECK" ] || [ "$CHECK" != "no" -a "$CHECK" != "yes" -a "$CHECK" != "force" ]; then
  echo "set CHECK parameter to no"| tee -a "$PRD"/log_processing_parameters.txt
  export CHECK="no"
else
  echo "CHECK parameter is "$CHECK""| tee -a "$PRD"/log_processing_parameters.txt
fi

if [ -z "$REGISTRATION" ]; then
  echo "set REGISTRATION parameter to regular"| tee -a "$PRD"/log_processing_parameters.txt
  REGISTRATION="regular"
else
  echo "REGISTRATION parameter is "$REGISTRATION""| tee -a "$PRD"/log_processing_parameters.txt
fi

if [ -z "$REGION_MAPPING_CORR" ]; then
  echo "set REGION_MAPPING_CORR parameter to 0.42"| tee -a "$PRD"/log_processing_parameters.txt
  export REGION_MAPPING_CORR=0.42
else
  echo "REGION_MAPPING_CORR parameter is "$REGION_MAPPING_CORR""| tee -a "$PRD"/log_processing_parameters.txt
fi

if [ -z "$NUMBER_TRACKS" ] || ! [[ "$NUMBER_TRACKS" =~ ^[0-9]+$ ]]; then
  echo "set NUMBER_TRACKS parameter to 10.000.000" | tee -a "$PRD"/log_processing_parameters.txt
  NUMBER_TRACKS=10000000
else
  echo "NUMBER_TRACKS parameter is "$NUMBER_TRACKS"" | tee -a "$PRD"/log_processing_parameters.txt
fi

# TODO: check if list of integers
if [ -z "$K_LIST" ]; then
  echo "set K_LIST parameter to empty" | tee -a "$PRD"/log_processing_parameters.txt
  K_LIST=""
else
  echo "K_LIST parameter is "$K_LIST"" | tee -a "$PRD"/log_processing_parameters.txt
fi

if [ -z "$TOPUP" ] || [ "$TOPUP" != "no" -a "$TOPUP" != "eddy_correct" ]; then
  echo "set TOPUP parameter to no" | tee -a "$PRD"/log_processing_parameters.txt
  TOPUP="no"
else
  echo "TOPUP parameter is "$TOPUP"" | tee -a "$PRD"/log_processing_parameters.txt
fi

if [ -z "$PE" ]; then
  echo "set PE (phase-encoding) parameter to auto (i.e. must be in header)" | tee -a "$PRD"/log_processing_parameters.txt
  PE="auto"
else
  echo "PE parameter is "$PE"" | tee -a "$PRD"/log_processing_parameters.txt
fi

if [ -z "$ACT" ] || [ "$ACT" != "none" -a "$ACT" != "fsl" -a "$ACT" != "freesurfer"]; then
  echo "set ACT parameter to fsl" | tee -a "$PRD"/log_processing_parameters.txt
  ACT="fsl"
else
  echo "ACT parameter is "$ACT"" | tee -a "$PRD"/log_processing_parameters.txt
fi

if [ -z "$SIFT" ] || [ "$SIFT" != "no" -a "$SIFT" != "sift"  -a "$SIFT" != "sift2" ]; then
  echo "set SIFT parameter to sift2" | tee -a "$PRD"/log_processing_parameters.txt
  SIFT="sift2"
else
  echo "SIFT parameter is "$SIFT"" | tee -a "$PRD"/log_processing_parameters.txt
fi

if [ -z "$SIFT_MULTIPLIER" ] || ! [[ "$NUMBER_TRACKS" =~ ^[0-9]+$ ]]; then
  echo "set SIFT_MULTIPLIER parameter to 10" | tee -a "$PRD"/log_processing_parameters.txt
  SIFT_MULTIPLIER=10
else
  echo "SIFT_MULTIPLIER parameter is "$SIFT_MULTIPLIER"" | tee -a "$PRD"/log_processing_parameters.txt
fi

if [ -z "$SEED" ] || [ "$SEED" != "gmwmi" -a "$SEED" != "dynamic" ]; then
  echo "set SEED parameter to dynamic" | tee -a "$PRD"/log_processing_parameters.txt
  SEED="dynamic"
else
  echo "SEED parameter is "$SEED"" | tee -a "$PRD"/log_processing_parameters.txt
fi

if [ -z "$ASEG" ] || [ "$ASEG" != "fs" -a "$ASEG" != "fsl" ]; then
  echo "set ASEG parameter to fsl" | tee -a "$PRD"/log_processing_parameters.txt
  ASEG="fsl"
else
  echo "ASEG parameter is "$ASEG"" | tee -a "$PRD"/log_processing_parameters.txt
fi

if [ -z  "$NB_THREADS" ] || ! [[ "$NUMBER_TRACKS" =~ ^[0-9]+$ ]]; then
  if [ -f ~/.mrtrix.conf ]; then
    number_threads_mrtrix_conf=$(grep 'NumberOfThreads' ~/.mrtrix.conf | cut -f 2 -d " ")
    if [ -n "$number_threads_mrtrix_conf" ]; then 
      echo "set number of threads to \
"$number_threads_mrtrix_conf" according to ~/.mrtrix.conf file" | tee -a "$PRD"/log_processing_parameters.txt
      NB_THREADS="$number_threads_mrtrix_conf"
    else
      echo "set number of threads to 1" | tee -a "$PRD"/log_processing_parameters.txt
      NB_THREADS=1
    fi
  else 
    echo "set number of threads to 1" | tee -a "$PRD"/log_processing_parameters.txt
    NB_THREADS=1
  fi
else
echo "number of threads is "$NB_THREADS"" | tee -a "$PRD"/log_processing_parameters.txt
fi

view_step=0


