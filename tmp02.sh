# export pial into text file
mkdir -p $PRD/surface
if [ ! -f $PRD/surface/lh.pial.asc ]; then
  echo "importing left pial surface from freesurfer"
  mris_convert "$FS"/"$SUBJ_ID"/surf/lh.pial "$PRD"/surface/lh.pial.asc
  # take care of the c_(ras) shift which is not done by FS (thks FS!)
  mris_info "$FS"/"$SUBJ_ID"/surf/lh.pial >& "$PRD"/surface/lhinfo.txt
fi

# triangles and vertices high
if [ ! -f $PRD/surface/lh_vertices_high.txt ]; then
  echo "extracting left vertices and triangles"
  python extract_high.py lh
fi

# decimation using remesher
if [ ! -f $PRD/surface/lh_vertices_low.txt ]; then
  echo "left decimation using remesher"
  # -> to mesh
  python txt2off.py $PRD/surface/lh_vertices_high.txt $PRD/surface/lh_triangles_high.txt $PRD/surface/lh_high.off
  #  decimation
  ./remesher/cmdremesher/cmdremesher $PRD/surface/lh_high.off $PRD/surface/lh_low.off
  # export to list vertices triangles
  python off2txt.py $PRD/surface/lh_low.off $PRD/surface/lh_vertices_low.txt $PRD/surface/lh_triangles_low.txt
fi

# create the left region mapping
if [ ! -f $PRD/surface/lh_region_mapping_low_not_corrected.txt ]; then
  echo "generating the left region mapping on the decimated surface"
  python region_mapping.py lh
fi

# correct
if [ ! -f $PRD/surface/lh_region_mapping_low.txt ]; then
    echo "correct the left region mapping"
    python correct_region_mapping.py lh
    echo "check left region mapping"
    python check_region_mapping.py lh
fi


