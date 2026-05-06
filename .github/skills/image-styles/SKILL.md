---
name: image-styles
description: Generate Drupal responsive image styles.
---

## Context Paths

**Note**: All paths are constructed from `agent.config.json` at session start.

- `{paths.breakpoints}` - Breakpoint definitions
- `{paths.config}/image.style.*.yml` - Output location

## Breakpoints Reference

```yaml
# Default breakpoints (verify in {paths.breakpoints})
xxs: 0-479px # Mobile small
xs: 480-767px # Mobile
md: 768-991px # Tablet
lg: 992-1199px # Desktop small
xl: 1200-1279px # Desktop
xxl: 1280-1920px # Desktop large
2k: 1921px+ # Big screens
```

## Effect Types

**image_scale_and_crop** (default) - Fixed dimensions, center crop
**image_scale** - Preserve ratio, no crop
**focal_point_scale_and_crop** - User focal point (requires focal_point module)

## Protocol

1. Calculate dimensions: `height = round(width / aspect_ratio)`
2. Generate YML with structure below
3. Name: `image.style.{component}_{breakpoint}.yml`
4. Include WebP conversion

## YML Templates

**Scale and Crop:**

```yaml
uuid: [uuid]
langcode: es
status: true
dependencies: {}
name: {name}_{bp}
label: '{Label} ({w}x{h})'
effects:
  [uuid1]:
    uuid: [uuid1]
    id: image_scale_and_crop
    weight: 1
    data:
      width: {w}
      height: {h}
      anchor: center-center
  [uuid2]:
    uuid: [uuid2]
    id: image_convert
    weight: 2
    data:
      extension: webp
```

**Scale Only:**

```yaml
effects:
    [uuid1]:
        uuid: [uuid1]
        id: image_scale
        data:
            width: { w }
            height: { h }
            upscale: false
    [uuid2]:
        uuid: [uuid2]
        id: image_convert
        data:
            extension: webp
```

**Focal Point:**

```yaml
dependencies:
    module:
        - focal_point
effects:
    [uuid1]:
        uuid: [uuid1]
        id: focal_point_scale_and_crop
        data:
            width: { w }
            height: { h }
            crop_type: focal_point
    [uuid2]:
        uuid: [uuid2]
        id: image_convert
        data:
            extension: webp
```

## Workflow

1. Extract: base dimensions, target breakpoints, effect type
2. Calculate: `height = round(width / aspect_ratio)` per breakpoint
3. Generate: One YML per breakpoint with unique UUIDs
4. Validate: ±1px tolerance, WebP enabled

## Examples

```
Input: "hero 1920x900, breakpoints md,lg,xl"
Output:
- image.style.hero_md.yml (991x464)
- image.style.hero_lg.yml (1199x562)
- image.style.hero_xl.yml (1279x600)
```

```
Input: "card thumbnail ratio 1.5, all breakpoints"
Output: 7 files (xxs:479x319, xs:767x511, md:991x661, lg:1199x799, xl:1279x853, xxl:1920x1280, 2k:2545x1697)
```

```
Input: "portrait focal point 800x1200, md/xl"
Output (focal_point_scale_and_crop):
- image.style.portrait_md.yml (991x1487)
- image.style.portrait_xl.yml (1279x1919)
```

## Real Example Reference

See [references/image.style.banner_fullhd.yml](references/image.style.banner_fullhd.yml) for a real Drupal image style YML with focal point and WebP conversion.
