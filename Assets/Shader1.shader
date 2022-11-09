Shader "Unlit/Shader1" {
    Properties {
        _Color ("Color", Color) = (0, 0, 0, 1)
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
            };

            struct v2f {
                float3 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float4 _Color;

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.vertex + float4(0.5, 0.5, 0.5, 0.0);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                fixed4 col = _Color;
                col.r += saturate(lerp(i.uv.x, i.uv.x, 1));
                col.g += saturate(lerp(i.uv.y, i.uv.y, 1));
                col.b += saturate(lerp(i.uv.z, i.uv.z, 1));
                return col;
            }
            ENDCG
        }
    }
}
