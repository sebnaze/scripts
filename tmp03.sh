# export pial into text file
if [ ! -f $PRD/surface/rh.pial.asc ]; then
  echo "importing right pial surface from freesurfer"
  mris_convert $FS/$SUBJ_ID/surf/rh.pial $PRD/surface/rh.pial.asc
  # take care of the c_(ras) shift which is not done by FS (thks FS!)
  mris_info $FS/$SUBJ_ID/surf/rh.pial >& $PRD/surface/rhinfo.txt
fi

# triangles and vertices high
if [ ! -f $PRD/surface/rh_vertices_high.txt ]; then
  echo "extracting right vertices and triangles"
  python extract_high.py rh
fi

# decimation using brainvisa
if [ ! -f $PRD/surface/rh_vertices_low.txt ]; then
  echo "right decimation using remesher"
  # -> to mesh
  python txt2off.py $PRD/surface/rh_vertices_high.txt $PRD/surface/rh_triangles_high.txt $PRD/surface/rh_high.off
  #  decimation
  ./remesher/cmdremesher/cmdremesher $PRD/surface/rh_high.off $PRD/surface/rh_low.off
  # export to list vertices triangles
  python off2txt.py $PRD/surface/rh_low.off $PRD/surface/rh_vertices_low.txt $PRD/surface/rh_triangles_low.txt
fi

# create the right region mapping
if [ ! -f $PRD/surface/rh_region_mapping_low_not_corrected.txt ]; then
  echo "generating the right region mapping on the decimated surface"
  python region_mapping.py rh
fi

# correct
if [ ! -f $PRD/surface/rh_region_mapping_low.txt ]; then
  echo " correct the right region mapping"
  python correct_region_mapping.py rh
  echo "check right region mapping"
  python check_region_mapping.py rh
fi

