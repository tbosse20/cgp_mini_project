Shader "Unlit/BackgroundColor"

{

    Properties{
        _Color1 ("Color1", Color) = (1,1,1,1)
        _Color2 ("Color2", Color) = (1,1,1,1)
    }

    SubShader
    {
        // Draw after all opaque geometry
        
        Tags { 
            "Queue" = "Transparent"
            "RenderType"="Transparent"
        }

        // Grab the screen behind the object into _BackgroundTexture
        GrabPass
        {
            "_BackgroundTexture"
        }

        // Render the object with the texture generated above, and invert the colors
           //Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {

            Cull Off
            ZWrite Off
            //Blend SrcAlpha OneMinusSrcAlpha
           
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float4 _Color1;
            float4 _Color2;
            
            #define TAU 6.28318530718

            struct MeshData{
                float4 vertex : POSITION;
                float4 uv0 : TEXCOORD0;
                float3 normals : NORMAL;
            };

            struct v2f
            {
                float4 grabPos : TEXCOORD2;
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD1; 
                float3  normal : TEXCOORD0;
            };

            v2f vert(MeshData v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex); // Convert to clip space
                o.normal = UnityObjectToWorldNormal( v.normals );
                //o.normal = v.normals;
                o.grabPos = ComputeGrabScreenPos(o.vertex); //Get correct texture coordinate
                o.uv = v.uv0;
                return o;
                
            }

            sampler2D _BackgroundTexture;

            float InverseLerp( float a, float b, float v ) {
                return (v-a)/(b-a);
            }
            
            
            float4 frag(v2f i) : SV_Target
            {
                float4 bgcolor = tex2Dproj(_BackgroundTexture, i.grabPos);
                _Color1 = 0.5 - bgcolor; //Color of shader compared to background 
                _Color2 = 0.3 - bgcolor; //Color of shader compared to background 
                float xOffset = cos(i.uv * TAU *  8 - _Time.y*0.8f) * 0.3 ;
                xOffset*= 1-i.uv.y; //Fade out
                float coswave = cos((i.uv.y + xOffset - _Time.y * 0.1f) * TAU * 5) * 0.5 + 0.5;
                //float tri = abs(frac((i.uv.x * 45 - _Time.y*0.5f)))* 1 - 0.8; 
                float4 gradient = lerp(_Color1, _Color2, coswave); //Moving 
                float4 nomove = lerp(_Color1, _Color2, i.uv.y); //not moving

                return nomove;
                
                         //* (abs(i.normal.y) < 0.999);
                //return gradient * (abs(i.normal.y) < 0.999); 
                
            }
            ENDCG
        }


Pass
        {

            Cull Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
           
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float4 _Color1;
            float4 _Color2;
            
            #define TAU 6.28318530718

            struct MeshData{
                float4 vertex : POSITION;
                float4 uv0 : TEXCOORD0;
                float3 normals : NORMAL;
            };

            struct v2f
            {
                float4 grabPos : TEXCOORD2;
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD1; 
                float3  normal : TEXCOORD0;
            };

            v2f vert(MeshData v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex); // Convert to clip space
                o.normal = UnityObjectToWorldNormal( v.normals );
                //o.normal = v.normals;
                o.grabPos = ComputeGrabScreenPos(o.vertex); //Get correct texture coordinate
                o.uv = v.uv0;
                return o;
                
            }

            sampler2D _BackgroundTexture;

            float InverseLerp( float a, float b, float v ) {
                return (v-a)/(b-a);
            }
            
            
            float4 frag(v2f i) : SV_Target
            {
                fixed4 col = fixed4(0, 0, 0, 0.5);
                return col;
                
                         //* (abs(i.normal.y) < 0.999);
                //return gradient * (abs(i.normal.y) < 0.999); 
                
            }
            ENDCG
        }

    }
}