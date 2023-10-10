// A square!
var<private> VERTICES:array<vec2<f32>,6> = array<vec2<f32>,6>(
    // Bottom left, bottom right, top left; then top left, bottom right, top right..
    vec2<f32>(0., 0.),
    vec2<f32>(1., 0.),
    vec2<f32>(0., 1.),
    vec2<f32>(0., 1.),
    vec2<f32>(1., 0.),
    vec2<f32>(1., 1.)
);

struct Camera {
    screen_pos: vec2<f32>,
    screen_size: vec2<f32>
}

struct GPUSprite {
    to_rect:vec4<f32>,
    from_rect:vec4<f32>
}

@group(0) @binding(0)
var<uniform> camera: Camera;
@group(0) @binding(1)
var<storage, read> s_sprites: array<GPUSprite>;

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) tex_coords: vec2<f32>,
}

@vertex
fn vs_storage_main(@builtin(vertex_index) in_vertex_index: u32, @builtin(instance_index) sprite_index:u32) -> VertexOutput {
    // We'll just look up the vertex data in those constant arrays
    let corner:vec4<f32> = vec4(s_sprites[sprite_index].to_rect.xy,0.,1.);
    let size:vec2<f32> = s_sprites[sprite_index].to_rect.zw;
    let tex_corner:vec2<f32> = s_sprites[sprite_index].from_rect.xy;
    let tex_size:vec2<f32> = s_sprites[sprite_index].from_rect.zw;
    let which_vtx:vec2<f32> = VERTICES[in_vertex_index];
    let which_uv: vec2<f32> = vec2(VERTICES[in_vertex_index].x, 1.0 - VERTICES[in_vertex_index].y);
    return VertexOutput(
        ((corner + vec4(which_vtx*size,0.,0.) - vec4(camera.screen_pos,0.,0.)) / vec4(camera.screen_size/2., 1.0, 1.0)) - vec4(1.0, 1.0, 0.0, 0.0),
        tex_corner + which_uv*tex_size
    );
}

struct InstanceInput {
    @location(0) to_rect: vec4<f32>,
    @location(1) from_rect: vec4<f32>,
};

@vertex
fn vs_vbuf_main(@builtin(vertex_index) in_vertex_index: u32, sprite_data:InstanceInput) -> VertexOutput {
    // We'll still just look up the vertex positions in those constant arrays
    let corner:vec4<f32> = vec4(sprite_data.to_rect.xy,0.,1.);
    let size:vec2<f32> = sprite_data.to_rect.zw;
    let tex_corner:vec2<f32> = sprite_data.from_rect.xy;
    let tex_size:vec2<f32> = sprite_data.from_rect.zw;
    let which_vtx:vec2<f32> = VERTICES[in_vertex_index];
    let which_uv: vec2<f32> = vec2(VERTICES[in_vertex_index].x, 1.0 - VERTICES[in_vertex_index].y);
    return VertexOutput(
        ((corner + vec4(which_vtx*size,0.,0.) - vec4(camera.screen_pos,0.,0.)) / vec4(camera.screen_size/2., 1.0, 1.0)) - vec4(1.0, 1.0, 0.0, 0.0),
        tex_corner + which_uv*tex_size
    );
}


// Now our fragment shader needs two "global" inputs to be bound:
// A texture...
@group(1) @binding(0)
var t_diffuse: texture_2d<f32>;
// And a sampler.
@group(1) @binding(1)
var s_diffuse: sampler;
// Both are in the same binding group here since they go together naturally.

// Our fragment shader takes an interpolated `VertexOutput` as input now
@fragment
fn fs_main(in:VertexOutput) -> @location(0) vec4<f32> {
    // And we use the tex coords from the vertex output to sample from the texture.
    let color:vec4<f32> = textureSample(t_diffuse, s_diffuse, in.tex_coords);
    if color.w < 0.2 { discard; }
    return color;
}





/*struct VertexInput {
    @builtin(vertex_index) vertex_idx: u32,
    @location(0) pos: vec2<i32>,
    @location(1) dim: u32,
    @location(2) uv: u32,
    @location(3) color: u32,
    @location(4) content_type: u32,
    @location(5) depth: f32,
}

struct VertexOutput {
    @invariant @builtin(position) position: vec4<f32>,
    @location(0) color: vec4<f32>,
    @location(1) uv: vec2<f32>,
    @location(2) @interpolate(flat) content_type: u32,
};

struct Params {
    screen_resolution: vec2<u32>,
    _pad: vec2<u32>,
};

@group(0) @binding(0)
var<uniform> params: Params;

@group(0) @binding(1)
var color_atlas_texture: texture_2d<f32>;

@group(0) @binding(2)
var mask_atlas_texture: texture_2d<f32>;

@group(0) @binding(3)
var atlas_sampler: sampler;

@vertex
fn vs_main(in_vert: VertexInput) -> VertexOutput {
    var pos = in_vert.pos;
    let width = in_vert.dim & 0xffffu;
    let height = (in_vert.dim & 0xffff0000u) >> 16u;
    let color = in_vert.color;
    var uv = vec2<u32>(in_vert.uv & 0xffffu, (in_vert.uv & 0xffff0000u) >> 16u);
    let v = in_vert.vertex_idx % 4u;

    switch v {
        case 1u: {
            pos.x += i32(width);
            uv.x += width;
        }
        case 2u: {
            pos.x += i32(width);
            pos.y += i32(height);
            uv.x += width;
            uv.y += height;
        }
        case 3u: {
            pos.y += i32(height);
            uv.y += height;
        }
        default: {}
    }

    var vert_output: VertexOutput;

    vert_output.position = vec4<f32>(
        2.0 * vec2<f32>(pos) / vec2<f32>(params.screen_resolution) - 1.0,
        in_vert.depth,
        1.0,
    );

    vert_output.position.y *= -1.0;

    vert_output.color = vec4<f32>(
        f32((color & 0x00ff0000u) >> 16u),
        f32((color & 0x0000ff00u) >> 8u),
        f32(color & 0x000000ffu),
        f32((color & 0xff000000u) >> 24u),
    ) / 255.0;

    var dim: vec2<u32> = vec2(0u);
    switch in_vert.content_type {
        case 0u: {
            dim = textureDimensions(color_atlas_texture);
            break;
        }
        case 1u: {
            dim = textureDimensions(mask_atlas_texture);
            break;
        }
        default: {}
    }

    vert_output.content_type = in_vert.content_type;

    vert_output.uv = vec2<f32>(uv) / vec2<f32>(dim);

    return vert_output;
}

@fragment
fn fs_main(in_frag: VertexOutput) -> @location(0) vec4<f32> {
    switch in_frag.content_type {
        case 0u: {
            return textureSampleLevel(color_atlas_texture, atlas_sampler, in_frag.uv, 0.0);
        }
        case 1u: {
            return vec4<f32>(in_frag.color.rgb, in_frag.color.a * textureSampleLevel(mask_atlas_texture, atlas_sampler, in_frag.uv, 0.0).x);
        }
        default: {
            return vec4<f32>(0.0);
        }
    }
}*/