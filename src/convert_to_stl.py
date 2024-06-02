from stl import mesh
import math
import numpy as np
from mpl_toolkits import mplot3d
from matplotlib import pyplot

triangles = []
with open("data/current.csv", "r") as f:
    for line in f:
        triangles.append([list(map(lambda x: float(x) * 10, i.split(","))) for i in line.strip().split("|")])

data = np.zeros(len(triangles), dtype=mesh.Mesh.dtype)
for i, triangle in enumerate(triangles):
    data['vectors'][i] = np.array(triangle)
my_mesh = mesh.Mesh(data)
my_mesh.save("data/test.stl")


# Create a new plot
figure = pyplot.figure()
axes = figure.add_subplot(projection="3d")

# Load the STL files and add the vectors to the plot
my_mesh = mesh.Mesh.from_file("data/test.stl")
axes.add_collection3d(mplot3d.art3d.Poly3DCollection(my_mesh.vectors))

# Auto scale to the mesh size
scale = my_mesh.points.flatten()
axes.auto_scale_xyz(scale, scale, scale)

# Show the plot to the screen
pyplot.show()
