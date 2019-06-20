Shader "Particles/Dissolve" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
 
        _BurnMask ("Burn Mask (RGB)", 2D) = "white" {}
        _BurnSize ("Burn Size", Range(0.0, 1.0)) = 0.15
        _BurnRamp ("Burn Ramp (RGB)", 2D) = "white" {}
        _BurnColor ("Burn Color", Color) = (1,1,1,1)
 
        _EmissionAmount ("Emission Amount", float) = 2.0
    }
    SubShader {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Cull Off
        Lighting Off
        ZWrite Off
        Fog { Mode Off }
        CGPROGRAM
        #pragma surface surf Lambert vertex:vert
        #pragma target 3.0
 
        fixed4 _Color;
        sampler2D _MainTex;
        sampler2D _BurnMask;
        sampler2D _BumpMap;
        sampler2D _BurnRamp;
        fixed4 _BurnColor;
        float _BurnSize;
        float _EmissionAmount;

        struct appdata_particles {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float3 texcoord : TEXCOORD0;
            float4 texcoord1 : TEXCOORD1;
            float4 texcoord2 : TEXCOORD2;
        };
 
        struct Input {
            float2 uv_MainTex;
            float burnRate;
        };
 
        void vert (inout appdata_particles v, out Input o) {
            UNITY_INITIALIZE_OUTPUT(Input,o);
            o.uv_MainTex = v.texcoord.xy;
            o.burnRate = v.texcoord.z;
        }
 
        void surf (Input IN, inout SurfaceOutput o) {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            clip(c.a - 0.01); // reject pixel having Alpha < 1%

            half test = tex2D(_BurnMask, IN.uv_MainTex).rgb - IN.burnRate;
            clip(test);
             
            if (test < _BurnSize && IN.burnRate > 0) {
                o.Emission = tex2D(_BurnRamp, float2(test * (1 / _BurnSize), 0)) * _BurnColor * _EmissionAmount;
            }
 
            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}