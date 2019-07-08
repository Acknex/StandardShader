Texture entSkin1;
Texture entSkin2;

sampler smpSurface = sampler_state
{
	Texture = <entSkin1>;
	MipFilter = Linear;
};
sampler smpNormalmap = sampler_state
{
	Texture = <entSkin2>;
	MipFilter = Linear;
};

struct vtx_in_t // vertexshader eingabe
{
	float4 pos : POSITION; // position des vertex in modellkoordinaten (exakt wie in MED (nur yz getauscht))
	float3 normal : NORMAL; // oberfl�chennormale des vertex
	float2 uv : TEXCOORD0; // texturkoordinate prim�res skinset
	float2 uv2 : TEXCOORD1; // texturkoordinate lightmapped skinset
	float3 tangent : TEXCOORD2;
};

struct vtx_out_t // vertexshader ausgabe
{
	float4 pos : POSITION;
	float3 normal : TEXCOORD0;
	float2 uv : TEXCOORD1;
	float3 wpos : TEXCOORD2;
	float3 tangent : TEXCOORD3;
	float2 uv2 : TEXCOORD4;
	float  fog : FOG;
};

struct pixel_out_t
{
	float4 color : COLOR0;
};

float4x4 matWorld;
float4x4 matWorldViewProj;

float4 vecTime;
float4 vecSunDir;
float4 vecViewDir;

/*********************************************************************************/

vtx_out_t vs(vtx_in_t _in)
{
    vtx_out_t _out;

    float4 pos = _in.pos;

    _out.pos = mul(pos, matWorldViewProj);

    _out.normal = mul(_in.normal, (float3x3)matWorld);
    _out.uv = _in.uv;
    _out.uv2 = _in.uv2;
    _out.wpos = mul(_in.pos, matWorld).xyz;

    _out.tangent = mul(_in.tangent.xyz, (float3x3)matWorld );

    _out.fog = _out.pos.w;

    return _out;
}

/*********************************************************************************/

float4 vecAmbient;
float4 vecDiffuse;
float4 vecSpecular;
float4 vecEmissive;
float fPower;
float fAmbient;

float4 vecFog;
float4 vecFogColor;

float4 vecColor;

float4 do_fog(vtx_out_t vtx, float4 color)
{
    return lerp(color, vecFogColor, vecFogColor.w * saturate((vtx.fog - vecFog.x) * vecFog.z));
}

pixel_out_t do_lighting(vtx_out_t vtx, float3 normal, float4 lightmap)
{
    float3 lighting = fAmbient;

    lighting += vecAmbient.rgb;
    lighting += vecDiffuse.rgb * saturate(-dot(vecSunDir.xyz, normal));

    float3 refl = reflect(vecSunDir, normal);

    lighting += vecSpecular.rgb * pow(saturate(-dot(refl, vecViewDir.xyz)), fPower);

    pixel_out_t pixel;
    pixel.color = do_fog(vtx, vecEmissive + float4(1.0 * lighting, 1) * lightmap * tex2D(smpSurface, vtx.uv));
    return pixel;
}

float3 do_normal(vtx_out_t vtx)
{
    float3x3 trafo;
    trafo[0] = normalize(vtx.tangent);
    trafo[1] = normalize(cross(vtx.tangent, vtx.normal));
    trafo[2] = normalize(vtx.normal);

    float3 normal = normalize(tex2D(smpNormalmap, vtx.uv).xyz - 0.5);

    return normalize(mul(normal, trafo));
}

float4 do_lightmap(vtx_out_t vtx)
{
    return tex2D(smpNormalmap, vtx.uv2);
}

pixel_out_t ps_default(vtx_out_t vtx)
{
    return do_lighting(vtx, vtx.normal, float4(1,1,1,1));
}

pixel_out_t ps_lightmapped(vtx_out_t vtx)
{
    return do_lighting(vtx, vtx.normal, do_lightmap(vtx));
}

pixel_out_t ps_normalmapped(vtx_out_t vtx)
{
    return do_lighting(vtx, do_normal(vtx), float4(1,1,1,1));
}

pixel_out_t ps_normalmapped_lightmapped(vtx_out_t vtx)
{
    return do_lighting(vtx, do_normal(vtx), do_lightmap(vtx));
}


technique std_default
{
	pass one
	{
		VertexShader = compile vs_3_0 vs();
		PixelShader  = compile ps_3_0 ps_default();
	}
}

technique std_normalmapped
{
	pass one
	{
		VertexShader = compile vs_3_0 vs();
		PixelShader  = compile ps_3_0 ps_normalmapped();
	}
}

technique std_lightmapped
{
	pass one
	{
		VertexShader = compile vs_3_0 vs();
		PixelShader  = compile ps_3_0 ps_lightmapped();
	}
}

technique std_normalmapped_lightmapped
{
	pass one
	{
		VertexShader = compile vs_3_0 vs();
		PixelShader  = compile ps_3_0 ps_normalmapped_lightmapped();
	}
}
