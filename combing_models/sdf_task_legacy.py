import numpy as np 

sdf = np.load('./result_1_512sdf.npy')

# Extract the points that lie on the surface (i.e., have a signed distance value close to zero)
threshold = 0.1  # Change this value to adjust the surface thickness

x, y, z = np.meshgrid(np.arange(sdf.shape[0]), np.arange(sdf.shape[1]), np.arange(sdf.shape[2]))
points = np.vstack((x.ravel(), y.ravel(), z.ravel())).T

print(points)

# Sample the signed distance function at the grid points
distances = sdf[x, y, z]

print("dis")
print(distances.shape)

surface_points = []
for x in range(0,512):
    for y in range(0,512):
        for z in range(0,512):
            if distances[x,y,z] < threshold:
                surface_points.append([x,y,z])

print("we want form (x,y,z):")

np.save("point_cloud_1", surface_points)
