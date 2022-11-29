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
    half4 postNormal : TEXCOORD2;
    half3 viewDir : POSITION1;
};

float4 _BaseColor;
float _Height;

sampler2D _HardNoiseTex;
float4 _HardNoiseTex_ST;
sampler2D _SoftNoiseTex;
float4 _SoftNoiseTex_ST;

sampler2D _CameraDepthTexture;

float _Test;
float _Test2;

v2f generalVert (appdata v) {
    v2f o;

    o.vertex = UnityObjectToClipPos(v.vertex);
    o.postNormal = v.normal;
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
                