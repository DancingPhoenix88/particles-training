Shader "Custom/WavingDissolve" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
 
        _BurnMask ("Burn Mask (RGB)", 2D) = "white" {}
        _BurnRate ("Burn Rate", Range(0.0, 1.0)) = 0
        _BurnSize ("Burn Size", Range(0.0, 1.0)) = 0.15
        _BurnRamp ("Burn Ramp (RGB)", 2D) = "white" {}
        _BurnColor ("Burn Color", Color) = (1,1,1,1)
 
        _EmissionAmount ("Emission Amount", float) = 2.0

        _WaveSpeed ("Wave Speed", Range(0.0, 10.0)) = 1.0
        _DisplaceAmount ("Displace Amount", Range(0.0, 10.0)) = 0.3
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
        float _BurnRate;
        float _BurnSize;
        float _EmissionAmount;
        float _WaveSpeed;
        float _DisplaceAmount;

        struct appdata_particles {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float3 texcoord : TEXCOORD0;
            float4 texcoord1 : TEXCOORD1;
            float4 texcoord2 : TEXCOORD2;
        };
 
        struct Input {
            float2 uv_MainTex;
        };
 
        void vert (inout appdata_particles v, out Input o) {
            UNITY_INITIALIZE_OUTPUT(Input,o);
            o.uv_MainTex = v.texcoord.xy;
            v.vertex.xyz += v.normal * sin( _Time.y * v.vertex.x * _WaveSpeed ) * _DisplaceAmount;
        }
 
        void surf (Input IN, inout SurfaceOutput o) {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            clip(c.a - 0.01); // reject pixel having Alpha < 1%

            half test = tex2D(_BurnMask, IN.uv_MainTex).rgb - _BurnRate;
            clip(test);
             
            if (test < _BurnSize && _BurnRate > 0) {
                o.Emission = tex2D(_BurnRamp, float2(test * (1 / _BurnSize), 0)) * _BurnColor * _EmissionAmount;
            }
 
            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}