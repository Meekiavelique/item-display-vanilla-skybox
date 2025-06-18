# item-display-vanilla-skybox
Minecraft vanilla skybox based on item display


**Fragment Shader (`rendertype_item_entity_translucent_cull.fsh`)**
- Detects items with alpha value 254 in their texture
- When detected, calculates ray direction from player view matrix

**Alpha Detection System**
```glsl
ALPHA_EFFECT(254) {
    vec3 rayDir = normalize(mat3(ModelViewMat) * vertexPosition);
    vec3 skyColor = getMinecraftSkyWithClouds(rayDir);
    fragColor = vec4(skyColor, 1.0);
    return;
}
```

**Summoning the skybox item display**
```
/summon item_display ~ ~ ~ {transformation:{left_rotation:[0f,0f,0f,1f],right_rotation:[0f,0f,0f,1f],translation:[0f,0f,0f],scale:[-5f,-5f,-5f]},item:{id:"minecraft:leather_horse_armor",count:1,components:{"minecraft:item_model":"skybox"}}}
````

The current `rendertype_item_entity_translucent_cull.fsh` contains a example skybox with 2D clouds based on https://www.shadertoy.com/view/4tdSWr
