Shader "Unlit/Circle" {
    Properties {
        _BaseColor ("Base color", Color) = (0, 0, .7, 1)
        _IntersectColor ("Intersect color", Color) = (0, 0, .7, 1)
        _Height ("Height", range(0, 25)) = 15.0
        _FadeLength ("Fade length", float) = 10.0
    }

    SubShader {
        
        Tags {
            "RenderType" = "Opaque"
            "Queue" = "Transparent"
            }
    
        Blend SrcAlpha OneMinusSrcAlpha 

        Pass {
            
            Cull Off
            ZWrite Off
            // ZTest Greater

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenuv : TEXCOORD1; // ############
                float4 worldPos : TEXCOORD2;
                // half3 worldNormal : TEXCOORD3;
                // half3 normal : TEXCOORD4;
            };

            float4 _BaseColor;
            sampler2D _CameraDepthTexture; // ############
            float _Height; 

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.uv);
                o.uv = v.uv;
                o.screenuv = ComputeScreenPos(o.vertex); // ############
                COMPUTE_EYEDEPTH(o.screenuv.z); // ############
                // o.worldNormal = UnityObjectToWorldNormal(v.normal);
                // o.normal = v.normal;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                float4 col = _BaseColor;

                float height = pow((_Height + 10) / 10, 5); // Recalculate height
                // height /= pow(i.uv.x, 1); // Depend to uv scale
                col.a *= 1. - saturate(abs(i.uv.y - 0.5) * height);

                // col.Emission = _BaseColor.rgb; // Add Emission

                return col;
            }
            ENDCG
        }

        // Pass {
            
        //     Cull Front
        //     ZWrite Off
        //     ZTest Greater

        //     CGPROGRAM
        //     #pragma vertex vert
        //     #pragma fragment frag

        //     #include "UnityCG.cginc"

        //     struct appdata {
        //         float4 vertex : POSITION;
        //         float4 uv : TEXCOORD0;
        //         float3 normal : NORMAL;
        //     };

        //     struct v2f {
        //         float4 uv : TEXCOORD0;
        //         float4 vertex : SV_POSITION;
        //         float4 screenuv : TEXCOORD1; // ############
        //         float4 worldPos : TEXCOORD2;
        //         // half3 worldNormal : TEXCOORD3;
        //         // half3 normal : TEXCOORD4;
        //     };

        //     float4 _BaseColor;
        //     float4 _IntersectColor;
        //     sampler2D _CameraDepthTexture; // ############
        //     float _FadeLength;

        //     v2f vert (appdata v) {
        //         v2f o;
        //         o.vertex = UnityObjectToClipPos(v.vertex);
        //         o.worldPos = mul(unity_ObjectToWorld, v.uv);
        //         o.uv = v.uv;
        //         o.screenuv = ComputeScreenPos(o.vertex); // ############
        //         COMPUTE_EYEDEPTH(o.screenuv.z); // ############
        //         // o.worldNormal = UnityObjectToWorldNormal(v.normal);
        //         // o.normal = v.normal;
        //         return o;
        //     }

        //     fixed4 frag (v2f i) : SV_Target {

        //         fixed4 col = _IntersectColor;
        //         float sceneZ = LinearEyeDepth(
        //             SAMPLE_DEPTH_TEXTURE_PROJ(
        //                 _CameraDepthTexture,
        //             UNITY_PROJ_COORD(i.screenuv)
        //             ));
        //         float partZ = i.screenuv.z;
        //         float diff = sceneZ - partZ;
        //         float intersect = saturate(pow(_FadeLength * 2, 5) * diff);
        //         fixed4 test = fixed4(lerp(i.uv, _BaseColor, intersect));

        //         col.a *= test;

        //         return col;
        //     }
        //     ENDCG
        // }
    }
}
