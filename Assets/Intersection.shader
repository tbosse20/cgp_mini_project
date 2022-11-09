// https://forum.unity.com/threads/depth-intersection-shader-not-accurate.529078/ 

Shader "Unlit/Intersection" {
    Properties {
        [Header(General)]
        _BaseColor("Color", Color) = (1, 0, 0, 1)
        _TransOOS ("OOS transparency", range(0, 1)) = 1.0

        [Header(Major gradient)]
        _TransL ("Opacity", range(0, 1)) = .5
        _UpperL ("Upper", range(0, 2)) = .7
        _LowerL ("Lower", range(-1, 1)) = .0

        [Header(Minor gradient)]
        _TransS ("Opacity", range(0, 1)) = .9
        _UpperS ("Upper", range(0, 1)) = .05
        _LowerS ("Lower", range(-1, 1)) = .03
    }

    SubShader {

        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask RGB
        Cull Off
        ZWrite Off

        Tags {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        // In seight 
        Pass {
            ZTest LEqual

            CGPROGRAM
            #include "Intersection_plugin.cginc"
 
            fixed4 frag (v2f i) : SV_Target {
                fixed4 col = _BaseColor;
                col.a *= intersection(i);
                return col;
            }
            ENDCG
        }

        // Out of seight
        Pass {
            ZTest GEqual
            
            CGPROGRAM
            #include "Intersection_plugin.cginc"

            fixed4 frag (v2f i) : SV_Target {
                fixed4 col = _BaseColor;
                col.a *= intersection(i);
                col.a *= _TransOOS;
                return col;
            }
            ENDCG
        }
    }
}