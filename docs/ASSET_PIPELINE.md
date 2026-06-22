# Realistic scan asset pipeline

The repository runs without external assets. It uses procedural 3D stand-ins by default.

To add realistic scan assets:

1. Find compatible free assets from sources such as Poly Haven, ambientCG, or properly licensed Sketchfab models.
2. Download raw files into `assets/scans/source/`.
3. Use Blender to reduce polygon count.
4. Export `.glb` files into `assets/scans/reduced/`.
5. Record credits in `assets/CREDITS.md`.

Suggested prop slots:

```text
assets/scans/reduced/barrel.glb
assets/scans/reduced/wooden_crate.glb
assets/scans/reduced/rock_cluster.glb
assets/scans/reduced/stone_ruin.glb
assets/scans/reduced/gnarled_tree.glb
assets/scans/reduced/medieval_cart.glb
assets/scans/reduced/weathered_statue.glb
```

Recommended budgets:

- tiny prop: 300–1,000 triangles,
- common prop: 1,000–3,500 triangles,
- hero prop: 4,000–8,000 triangles,
- total visible board props: under roughly 200k triangles.
