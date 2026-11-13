#!/usr/bin/env python3
"""Headless Blender asset converter: itch.io model pack -> Quake-ready model.

Runs inside Blender, not with system python:

    blender --background --python tools/blender_asset.py -- --input art/tree.fbx --name tree
    blender --background --python tools/blender_asset.py -- --selftest

What it does (deterministic, repeatable, committed to the repo):
  1. starts from an empty scene (no default cube, no leftover units)
  2. imports .glb/.gltf/.fbx/.obj
  3. triangulates, applies transforms, recenters the origin
     (feet = bottom-center for monsters/items, center for props/decor)
  4. reports triangle/vertex counts against Quake MDL limits
  5. writes .obj + .mtl into slipgate/models/src/ for the MDL step

Quake MDL export is NOT attempted here: the exporter addons are version-fragile
on Blender 4.x, so the .obj is the stable intermediate. See tools/README.md.
"""
import sys
import json
from pathlib import Path

import bpy
from mathutils import Vector

# Quake MDL hard limits (id Tech 2): 2000 tris / 1024 verts per frame is the
# practical ceiling; beyond it the model gets dropped or truncated in-game.
TRI_WARN, VERT_WARN = 2000, 1024


def argv() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def opt(name: str, default=None):
    a = argv()
    return a[a.index(name) + 1] if name in a else default


def flag(name: str) -> bool:
    return name in argv()


def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scn = bpy.context.scene
    scn.unit_settings.system = "METRIC"
    scn.unit_settings.scale_length = 1.0


def import_model(path: Path) -> None:
    ext = path.suffix.lower()
    if ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=str(path))
    elif ext == ".fbx":
        try:
            bpy.ops.import_scene.fbx(filepath=str(path))
        except AttributeError:
            bpy.ops.preferences.addon_enable(module="io_scene_fbx")
            bpy.ops.import_scene.fbx(filepath=str(path))
    elif ext == ".obj":
        if hasattr(bpy.ops.wm, "obj_import"):  # Blender 4.x
            bpy.ops.wm.obj_import(filepath=str(path))
        else:
            bpy.ops.import_scene.obj(filepath=str(path))
    else:
        raise SystemExit(f"ERROR: unsupported format {ext} (use .glb .gltf .fbx .obj)")


def mesh_objects() -> list:
    return [o for o in bpy.context.scene.objects if o.type == "MESH"]


def prepare(scale: float, origin: str) -> dict:
    meshes = mesh_objects()
    if not meshes:
        raise SystemExit("ERROR: no mesh objects imported")

    # bake object transforms, then scale about the world origin
    for ob in meshes:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    if scale != 1.0:
        bpy.ops.transform.resize(value=(scale, scale, scale))
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    # triangulate every mesh (MDL is triangles only)
    for ob in meshes:
        bpy.context.view_layer.objects.active = ob
        mod = ob.modifiers.new("tri", "TRIANGULATE")
        mod.quad_method = "BEAUTY"

    # world-space bounds
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for ob in meshes:
        for c in ob.bound_box:
            w = ob.matrix_world @ Vector(c)
            lo = Vector((min(lo[i], w[i]) for i in range(3)))
            hi = Vector((max(hi[i], w[i]) for i in range(3)))

    # origin: Quake models sit at their feet (z=0) with the pivot centered in x/y
    if origin == "feet":
        off = Vector((-(lo.x + hi.x) / 2, -(lo.y + hi.y) / 2, -lo.z))
    elif origin == "center":
        off = Vector((-(lo.x + hi.x) / 2, -(lo.y + hi.y) / 2, -(lo.z + hi.z) / 2))
    else:  # keep
        off = Vector((0, 0, 0))
    if off.length:
        bpy.context.view_layer.objects.active = meshes[0]
        for ob in meshes:
            ob.location += off
        bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)
        lo, hi = lo + off, hi + off

    for ob in meshes:
        ob.data.calc_loop_triangles()
    tris = sum(len(ob.data.loop_triangles) for ob in meshes)
    verts = sum(len(ob.data.vertices) for ob in meshes)
    return {
        "objects": len(meshes),
        "vertices": verts,
        "triangles": tris,
        "size": [round(hi[i] - lo[i], 3) for i in range(3)],
        "bounds_z": [round(lo.z, 3), round(hi.z, 3)],
    }


def export_obj(outdir: Path, name: str) -> Path:
    outdir.mkdir(parents=True, exist_ok=True)
    out = outdir / f"{name}.obj"
    for ob in mesh_objects():
        ob.select_set(True)
    if hasattr(bpy.ops.wm, "obj_export"):
        # Blender 4.3: the flag is apply_modifiers (export_apply is 4.4+)
        bpy.ops.wm.obj_export(filepath=str(out), export_triangulated_mesh=True,
                              apply_modifiers=True, export_materials=True)
    else:
        bpy.ops.export_scene.obj(filepath=str(out), use_triangles=True, use_materials=True)
    return out


def make_cube() -> None:
    bpy.ops.mesh.primitive_cube_add(size=32.0)


def main() -> None:
    reset_scene()

    if flag("--selftest"):
        make_cube()
        stats = prepare(1.0, "feet")
        out = export_obj(Path("/tmp"), "selftest_cube")
        print("SELFTEST OK", json.dumps(stats))
        print("wrote", out)
        return

    src = opt("--input")
    if not src:
        raise SystemExit("ERROR: --input <model file> required (or --selftest)")
    src = Path(src)
    if not src.is_file():
        raise SystemExit(f"ERROR: {src} not found")

    name = opt("--name", src.stem.lower().replace(" ", "_"))
    scale = float(opt("--scale", "1.0"))
    origin = opt("--origin", "feet")

    import_model(src)
    stats = prepare(scale, origin)
    out = export_obj(ROOT_MODELS, name)

    print("\n=== RESULT ===")
    print(json.dumps({"name": name, "obj": str(out), **stats}, indent=2))

    warnings = []
    if stats["triangles"] > TRI_WARN:
        warnings.append(f"{stats['triangles']} triangles > {TRI_WARN} MDL limit: decimate it")
    if stats["vertices"] > VERT_WARN:
        warnings.append(f"{stats['vertices']} vertices > {VERT_WARN} MDL limit: decimate it")
    for w in warnings:
        print("WARN:", w)
    if not warnings:
        print("Within Quake MDL limits.")


ROOT_MODELS = Path(__file__).resolve().parent.parent / "slipgate" / "models" / "src"

if __name__ == "__main__":
    main()