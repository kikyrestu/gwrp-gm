"""
Create a minimal flat plane DFF model for SA-MP texture display.
This creates a RenderWare DFF with a single quad (two triangles) that
can be used with TextDrawSetPreviewModel to display custom textures.
"""
import struct
import os

# RenderWare version for GTA:SA
RW_VERSION = 0x1803FFFF

# Section types
SECTION_STRUCT = 1
SECTION_STRING = 2
SECTION_EXTENSION = 3
SECTION_CLUMP = 0x10
SECTION_FRAME_LIST = 0x0E
SECTION_GEOMETRY_LIST = 0x1A
SECTION_GEOMETRY = 0x0F
SECTION_MATERIAL_LIST = 0x08
SECTION_MATERIAL = 0x07
SECTION_TEXTURE = 0x06
SECTION_ATOMIC = 0x14
SECTION_BIN_MESH_PLG = 0x050E


def make_section(stype, data, ver=RW_VERSION):
    return struct.pack('<III', stype, len(data), ver) + data


def build_flat_dff(texture_name='phoneframe'):
    """Build a minimal DFF with a flat rectangle."""
    
    # ================================================================
    # Frame List (1 frame: root)
    # ================================================================
    frame_count = 1
    # Frame data: rotation matrix (3x3 identity) + position (0,0,0) + parent (-1) + flags
    frame_data = struct.pack('<I', frame_count)
    # 3x3 rotation matrix (identity)
    frame_data += struct.pack('<9f', 1,0,0, 0,1,0, 0,0,1)
    # Position
    frame_data += struct.pack('<3f', 0.0, 0.0, 0.0)
    # Parent index (-1 = no parent), flags
    frame_data += struct.pack('<iI', -1, 0)
    
    frame_struct = make_section(SECTION_STRUCT, frame_data)
    # Frame name extension
    frame_name = b'root\x00'
    frame_ext = make_section(SECTION_EXTENSION, make_section(SECTION_STRING, frame_name))
    frame_list = make_section(SECTION_FRAME_LIST, frame_struct + frame_ext)
    
    # ================================================================
    # Geometry (flat quad with UV mapping)
    # ================================================================
    # 4 vertices forming a quad, 2 triangles
    num_verts = 4
    num_tris = 2
    
    # Geometry flags
    GEO_TRISTRIP = 0x01
    GEO_POSITIONS = 0x02
    GEO_TEXTURED = 0x04
    GEO_NORMALS = 0x10
    GEO_NATIVE = 0x01000000
    
    geo_flags = GEO_POSITIONS | GEO_TEXTURED | GEO_NORMALS
    
    # Geometry struct header
    geo_data = struct.pack('<HHI', geo_flags, num_tris, num_verts)
    # Morph target count
    geo_data += struct.pack('<I', 1)
    
    # Prelit colors (not used, but part of format) - skipped since no flag
    
    # UV coordinates (1 set)
    uvs = [
        (0.0, 0.0),  # top-left
        (1.0, 0.0),  # top-right
        (1.0, 1.0),  # bottom-right
        (0.0, 1.0),  # bottom-left
    ]
    for u, v in uvs:
        geo_data += struct.pack('<ff', u, v)
    
    # Triangles: vertex2, vertex1, materialIndex, vertex3
    # Tri 1: 0-1-2
    geo_data += struct.pack('<HHHH', 1, 0, 0, 2)
    # Tri 2: 0-2-3
    geo_data += struct.pack('<HHHH', 2, 0, 0, 3)
    
    # Morph target: bounding sphere + vertices + normals
    # Bounding sphere: center(3f) + radius(1f)
    geo_data += struct.pack('<4f', 0.0, 0.0, 0.0, 1.5)
    # Has vertices, has normals
    geo_data += struct.pack('<II', 1, 1)
    
    # Vertices (flat plane, 1x1.5 aspect ratio for phone)
    verts = [
        (-0.5, 0.0, 0.75),   # top-left
        (0.5, 0.0, 0.75),    # top-right
        (0.5, 0.0, -0.75),   # bottom-right
        (-0.5, 0.0, -0.75),  # bottom-left
    ]
    for x, y, z in verts:
        geo_data += struct.pack('<fff', x, y, z)
    
    # Normals (all pointing up)
    for _ in range(num_verts):
        geo_data += struct.pack('<fff', 0.0, 1.0, 0.0)
    
    geo_struct = make_section(SECTION_STRUCT, geo_data)
    
    # Material List
    mat_count_data = struct.pack('<I', 1)  # 1 material
    mat_count_data += struct.pack('<i', -1)  # material index (-1 = inline)
    
    # Material struct
    mat_data = struct.pack('<I', 0)  # flags
    mat_data += struct.pack('<4B', 255, 255, 255, 255)  # color RGBA
    mat_data += struct.pack('<I', 0)  # unused
    mat_data += struct.pack('<iI', 1, 0)  # texture count=1 (has texture), ambient
    mat_data += struct.pack('<fff', 1.0, 1.0, 1.0)  # ambient, specular, diffuse
    mat_struct = make_section(SECTION_STRUCT, mat_data)
    
    # Texture
    tex_data = struct.pack('<HH', 0x0106, 0)  # filter flags, pad
    tex_struct = make_section(SECTION_STRUCT, tex_data)
    tex_name = make_section(SECTION_STRING, texture_name.encode('ascii') + b'\x00')
    tex_mask = make_section(SECTION_STRING, b'\x00')
    tex_ext = make_section(SECTION_EXTENSION, b'')
    texture = make_section(SECTION_TEXTURE, tex_struct + tex_name + tex_mask + tex_ext)
    
    mat_ext = make_section(SECTION_EXTENSION, b'')
    material = make_section(SECTION_MATERIAL, mat_struct + texture + mat_ext)
    
    matlist_struct = make_section(SECTION_STRUCT, mat_count_data)
    matlist = make_section(SECTION_MATERIAL_LIST, matlist_struct + material)
    
    # Geometry extension (bin mesh plugin)
    # BinMesh: type(uint32) + numSplits(uint32) + totalIndices(uint32)
    binmesh_data = struct.pack('<III', 0, 1, 6)  # triList, 1 split, 6 indices
    # Split: indexCount(uint32) + materialIndex(uint32) + indices
    binmesh_data += struct.pack('<II', 6, 0)  # 6 indices, material 0
    binmesh_data += struct.pack('<6I', 0, 1, 2, 0, 2, 3)  # vertex indices
    binmesh_ext = make_section(SECTION_BIN_MESH_PLG, binmesh_data)
    
    geo_ext = make_section(SECTION_EXTENSION, binmesh_ext)
    geometry = make_section(SECTION_GEOMETRY, geo_struct + matlist + geo_ext)
    
    # Geometry List
    geolist_struct = make_section(SECTION_STRUCT, struct.pack('<I', 1))  # 1 geometry
    geolist = make_section(SECTION_GEOMETRY_LIST, geolist_struct + geometry)
    
    # ================================================================
    # Atomic (links frame 0 to geometry 0)
    # ================================================================
    atomic_data = struct.pack('<II', 0, 0)  # frame index, geometry index
    # Flags: rpATOMICRENDER (0x04)
    atomic_data += struct.pack('<II', 0x04, 0)
    atomic_struct = make_section(SECTION_STRUCT, atomic_data)
    atomic_ext = make_section(SECTION_EXTENSION, b'')
    atomic = make_section(SECTION_ATOMIC, atomic_struct + atomic_ext)
    
    # ================================================================
    # Clump
    # ================================================================
    clump_data = struct.pack('<III', 1, 0, 0)  # numAtomics, numLights, numCameras
    clump_struct = make_section(SECTION_STRUCT, clump_data)
    clump_ext = make_section(SECTION_EXTENSION, b'')
    
    clump = make_section(SECTION_CLUMP, clump_struct + frame_list + geolist + atomic + clump_ext)
    
    return clump


if __name__ == '__main__':
    root = os.path.join(os.path.dirname(__file__), '..')
    
    # Phone frame DFF
    dff_data = build_flat_dff('phoneframe')
    dff_path = os.path.join(root, 'models', 'phoneframe.dff')
    with open(dff_path, 'wb') as f:
        f.write(dff_data)
    print(f'Created {dff_path} ({os.path.getsize(dff_path)} bytes)')
    
    # Wallpaper DFF  
    dff_data2 = build_flat_dff('phonewp')
    dff_path2 = os.path.join(root, 'models', 'phonewp.dff')
    with open(dff_path2, 'wb') as f:
        f.write(dff_data2)
    print(f'Created {dff_path2} ({os.path.getsize(dff_path2)} bytes)')
    
    print('Done!')
