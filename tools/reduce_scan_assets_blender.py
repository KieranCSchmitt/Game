#!/usr/bin/env python3
"""Batch reduce scan assets in Blender and export GLB files.

Usage:
  blender --background --python tools/reduce_scan_assets_blender.py -- --input assets/scans/source --output assets/scans/reduced --ratio 0.18
"""
from __future__ import annotations
import argparse, sys
from pathlib import Path
try:
    import bpy
except ImportError as exc:
    raise SystemExit('Run this with Blender Python.') from exc
SUPPORTED = {'.glb','.gltf','.fbx','.obj'}

def args():
    argv = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    p = argparse.ArgumentParser(); p.add_argument('--input', required=True); p.add_argument('--output', required=True); p.add_argument('--ratio', type=float, default=.18); return p.parse_args(argv)

def clear():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete()

def import_asset(path: Path):
    s = path.suffix.lower()
    if s in {'.glb','.gltf'}: bpy.ops.import_scene.gltf(filepath=str(path))
    elif s == '.fbx': bpy.ops.import_scene.fbx(filepath=str(path))
    elif s == '.obj': bpy.ops.wm.obj_import(filepath=str(path))
    else: raise ValueError(path)

def reduce(ratio: float):
    for obj in bpy.context.scene.objects:
        if obj.type != 'MESH': continue
        bpy.context.view_layer.objects.active = obj; obj.select_set(True)
        mod = obj.modifiers.new('CrownCinder_Decimate','DECIMATE'); mod.ratio = max(.03, min(1.0, ratio))
        bpy.ops.object.modifier_apply(modifier=mod.name); obj.select_set(False)

def export(path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB', export_apply=True, export_texcoords=True, export_normals=True, export_materials='EXPORT')

def main():
    a = args(); src = Path(a.input); out = Path(a.output)
    for p in [x for x in src.rglob('*') if x.suffix.lower() in SUPPORTED]:
        clear(); import_asset(p); reduce(a.ratio); export(out / f'{p.stem}.glb')

if __name__ == '__main__': main()
