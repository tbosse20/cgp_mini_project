// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"

struct appdata {
    float4 vertex : POSITION;
    float4 uv : TEXCOORD0;
    float4 normal : NORMAL;
};

struct v2f {
    float2 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
    half4 normal : TEXCOORD1;

    half3 viewDir : POSITION1;
    float3 normalDir : TEXCOORD2;
    float2 uvTexture : TEXCOORD3;
    float4 screenuv : TEXCOORD4;
    float4 worldPos : TEXCOORD5;
    float3 worldNormal : TEXCOORD6;
    float4 screenPos : TEXCOORD7;
};

float4 _BaseColor;

sampler2D _HardNoiseTex;
float4 _HardNoiseTex_ST;
sampler2D _SoftNoiseTex;
float4 _SoftNoiseTex_ST;

float _Height; 

float4 _IntersectColor;
float4 _IntersectColor2;
float _FadeLength;

sampler2D _CameraDepthTexture;

float _Test; 
float _Test2; 

v2f generalVert (appdata v) {
    v2f o;

    o.vertex = UnityObjectToClipPos(v.vertex);

    o.screenuv = ComputeScreenPos(o.vertex);
    COMPUTE_EYEDEPTH(o.screenuv.z);
    o.worldNormal = mul(unity_ObjectToWorld, v.normal).xyz;
    o.worldPos = mul(unity_ObjectToWorld, v.uv);
    o.uvTexture = TRANSFORM_TEX(v.uv, _SoftNoiseTex);
    o.viewDir = ObjSpaceViewDir(v.vertex);

    o.normal = v.normal;
    o.uv = v.uv;

    return o;
}

float3 getScale() {
    return float3(
        length(unity_ObjectToWorld._m00_m10_m20),
        length(unity_ObjectToWorld._m01_m11_m21),
        length(unity_ObjectToWorld._m02_m12_m22));
}

float getSceneZ(v2f i) {
    return LinearEyeDepth(
        SAMPLE_DEPTH_TEXTURE_PROJ(
            _CameraDepthTexture,
            UNITY_PROJ_COORD(i.screenuv)
            ));
}

void showAtScale(float scaleTarget) {
    float preTest = scaleTarget * unity_ObjectToWorld > 0;
    clip(preTest - 0.00001);
}

void showAtScale(float scaleTarget, float startTarget) {
    float preTest = scaleTarget * unity_ObjectToWorld > startTarget;
    clip(preTest - 0.00001);
}
                