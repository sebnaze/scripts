# quick script sent by tp to check visually if tracts and cortical surface are align
from  pylab import *
import matplotlib
import nibabel as nib
import os

# load structural image
#brain= nib.load('T1_2_diff.nii.gz').get_data()
brain= nib.load('aparcaseg_2_diff.nii.gz').get_data()
if len(brain.shape)==4 :
  brain = brain[:,:,:,0]

# load cortical surface
mesh_size = 10242 # single hemisphere mesh size as choosen in remesher
lh_vtx = np.fromfile('../surface/lh_vertices_low.txt',dtype=float, count=-1, sep=' ')
rh_vtx = np.fromfile('../surface/rh_vertices_low.txt',dtype=float, count=-1, sep=' ')
lh_vtx = lh_vtx.reshape(mesh_size,3)
rh_vtx = rh_vtx.reshape(mesh_size,3)
vtx = np.array([lh_vtx, rh_vtx]).reshape(2*mesh_size,3)
randidx = randint(mesh_size*2, size=(1,500))

# transformation matrices from LPS to RAS 
M = [[-1,0,0],[0,-1,0],[0,0,1]] 
A = [brain.shape[0], brain.shape[1], 0]
#A = [-126, -113.5634307861328, -54.10147857666016]
#M = loadtxt('diffusion_2_struct.mat')
#A = M[:3,3]-255
#M = M[:3,:3]

# transformation from surface mesh to structural space


# plot structural image and cortical surface
figure()
subplot(221)
imshow(brain[:, 64, :].T, origin='lower')
scatter(vtx[randidx,0], vtx[randidx,2], color='y', alpha=0.3)
subplot(222)
imshow(brain[64, :, :].T, origin='lower')
scatter(vtx[randidx,1], vtx[randidx,2], color='y', alpha=0.3)
subplot(223)
imshow(brain[:, :, 37].T, origin='lower')
scatter(vtx[randidx,0], vtx[randidx,1], color='y', alpha=0.3)

# plot tracts 
tck_file_list = os.listdir('tmp_ascii_tck')
for fname in tck_file_list[:1000]:
    lines = np.loadtxt('tmp_ascii_tck/' + fname)
    lines = dot(M, lines.T).T + A
    subplot(221)
    #imshow(brain[::, 64, ::-1].T)
    scatter(lines[:, 0], lines[:, 2], color='g', alpha=0.1)
    subplot(222)
    #imshow(brain[64, ::-1, ::-1].T)
    scatter(lines[:, 1], lines[:, 2], color='g', alpha=0.1)
    subplot(223)
    #imshow(brain[::, ::-1, 37].T)
    scatter(lines[:, 0], lines[:, 1], color='g', alpha=0.1)

show()
