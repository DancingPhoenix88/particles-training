// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Adapted to Unity from http://www.humus.name/index.php?page=3D&ID=80
Shader "Volume/CubeMapInteriorMapping"
{
    Properties
    {
        _RoomCube ("Room Cube Map", Cube) = "white" {}
        [Toggle(_USEOBJECTSPACE)] _UseObjectSpace ("Use Object Space", Float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
 
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
 
            #pragma shader_feature _USEOBJECTSPACE
         
            #include "UnityCG.cginc"
 
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };
 
            struct v2f
            {
                float4 pos : SV_POSITION;
            #ifdef _USEOBJECTSPACE
                float3 uvw : TEXCOORD0;
            #else
                float2 uv : TEXCOORD0;
            #endif
                float3 viewDir : TEXCOORD1;
            };
 
            samplerCUBE _RoomCube;
            float4 _RoomCube_ST;
 
            // psuedo random
            float3 rand3(float co){
                return frac(sin(co * float3(12.9898,78.233,43.2316)) * 43758.5453);
            }
         
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
 
            #ifdef _USEOBJECTSPACE
                // slight scaling adjustment to work around "noisy wall" when frac() returns a 0 on surface
                o.uvw = v.vertex * _RoomCube_ST.xyx * 0.999 + _RoomCube_ST.zwz;
 
                // get object space camera vector
                float4 objCam = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
                o.viewDir = v.vertex.xyz - objCam.xyz;
 
                // adjust for tiling
                o.viewDir *= _RoomCube_ST.xyx;
            #else
                // uvs
                o.uv = TRANSFORM_TEX(v.uv, _RoomCube);
 
                // get tangent space camera vector
                float4 objCam = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
                float3 viewDir = v.vertex.xyz - objCam.xyz;
                float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                float3 bitangent = cross(v.normal.xyz, v.tangent.xyz) * tangentSign;
                o.viewDir = float3(
                    dot(viewDir, v.tangent.xyz),
                    dot(viewDir, bitangent),
                    dot(viewDir, v.normal)
                    );
 
                // adjust for tiling
                o.viewDir *= _RoomCube_ST.xyx;
            #endif
                return o;
            }
         
            fixed4 frag (v2f i) : SV_Target
            {
            #ifdef _USEOBJECTSPACE
                // room uvws
                float3 roomUVW = frac(i.uvw);
 
                // raytrace box from object view dir
                float3 pos = roomUVW * 2.0 - 1.0;
                float3 id = 1.0 / i.viewDir;
                float3 k = abs(id) - pos * id;
                float kMin = min(min(k.x, k.y), k.z);
                pos += kMin * i.viewDir;
 
                // randomly flip & rotate cube map for some variety
                float3 flooredUV = floor(i.uvw);
                float3 r = rand3(flooredUV.x + flooredUV.y + flooredUV.z);
                float2 cubeflip = floor(r.xy * 2.0) * 2.0 - 1.0;
                pos.xz *= cubeflip;
                pos.xz = r.z > 0.5 ? pos.xz : pos.zx;
            #else
                // room uvs
                float2 roomUV = frac(i.uv);
 
                // raytrace box from tangent view dir
                float3 pos = float3(roomUV * 2.0 - 1.0, 1.0);
                float3 id = 1.0 / i.viewDir;
                float3 k = abs(id) - pos * id;
                float kMin = min(min(k.x, k.y), k.z);
                pos += kMin * i.viewDir;
 
                // randomly flip & rotate cube map for some variety
                float2 flooredUV = floor(i.uv);
                float3 r = rand3(flooredUV.x + 1.0 + flooredUV.y * (flooredUV.x + 1));
                float2 cubeflip = floor(r.xy * 2.0) * 2.0 - 1.0;
                pos.xz *= cubeflip;
                pos.xz = r.z > 0.5 ? pos.xz : pos.zx;
            #endif
 
                // sample room cube map
                fixed4 room = texCUBE(_RoomCube, pos.xyz);
                return fixed4(room.rgb, 1.0);
            }
            ENDCG
        }
    }
}
