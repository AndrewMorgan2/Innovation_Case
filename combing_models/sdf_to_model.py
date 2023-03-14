import numpy as np
from skimage import measure
from numpy.linalg import inv

#Two differnet calib_tensor && mat 
#So we go with either and see the difference 
calib_tensor = np.load("Something")
mat = np.load("Something")
combined_sdf = np.load("Something")

calib = calib_tensor[0].cpu().numpy()

calib_inv = inv(calib)
# Finally we do marching cubes
try:
    verts, faces, normals, values = measure.marching_cubes(combined_sdf, 0.5)
    # transform verts into world coordinate system
    trans_mat = np.matmul(calib_inv, mat)
    verts = np.matmul(trans_mat[:3, :3], verts.T) + trans_mat[:3, 3:4]
    verts = verts.T
    # in case mesh has flip transformation
    if np.linalg.det(trans_mat[:3, :3]) < 0.0:
        faces = faces[:,::-1]

    file = open('output_combined', 'w')

    for v in verts:
        file.write('v %.4f %.4f %.4f\n' % (v[0], v[1], v[2]))
    if faces is not None:
        for f in faces:
            if f[0] == f[1] or f[1] == f[2] or f[0] == f[2]:
                continue
            f_plus = f + 1
            file.write('f %d %d %d\n' % (f_plus[0], f_plus[2], f_plus[1]))
    file.close()
except:
    print('error cannot marching cubes')
    #return -1