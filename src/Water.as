/*
 * 99 little bugs in the code
 * 99 little bugs in the code
 * Take one down, patch it around
 * 117 little bugs in the code
 */

package  
{
	import adobe.utils.CustomActions;
	import flare.basic.Scene3D;
	import flare.core.Surface3D;
	import flare.core.Texture3D;
	import flare.flsl.FLSLInput;
	import flare.flsl.FLSLMaterial;
	import flare.flsl.FLSLShader;
	import flare.primitives.Plane;
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.display.ShaderJob;
	import flash.display3D.textures.Texture;
	import flash.events.ShaderEvent;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getTimer;
	/**
	 * ...
	 * @author Daniel Green
	 */
	public class Water 
	{
		private var _scene:Scene3D;
		
		// -*- Simulation properties -*-
		private var _gridSize:uint; /**< Simulation grid size. */
		private var _waterSurface:Surface3D; /**< Surface information that will be uploaded to the plane. */
		private var _vertexData:Vector.<Number>;
		[Embed(source = "/../bin/data/water_update.pbj", mimeType = "application/octet-stream")]
		private var UpdateShader:Class;
		private var _updateShader:Shader; /**< Computation shader for waves. */
		[Embed(source = "/../bin/data/water_normals.pbj", mimeType = "application/octet-stream")]
		private var NormalsShader:Class;
		private var _normalsShader:Shader;
		[Embed(source = "/../bin/data/water_drop.pbj", mimeType = "application/octet-stream")]
		private var DropShader:Class;
		private var _dropShader:Shader;
		private var _elapsedTime:Number = 0.0;
		
		// -*- Materials -*-
		[Embed(source = "/../bin/data/water.flsl.compiled", mimeType = "application/octet-stream")]
		private var _shaderClass:Class;
		private var _shader:FLSLMaterial; /**< Shader for the water. */
		
		// -*- Renderables -*-
		private var _plane:Plane;    /**< Final rendererd geometry. */
		private var _planeSize:uint; /**< Size of the plane geometry. */
		
		// -*- Embedded textures and shit -*-
		[Embed(source="/../bin/data/cubemap.png", mimeType="application/octet-stream")]
		private var CubemapTextureBytes:Class;
		[Embed(source = "../bin/data/normals_2.JPG", mimeType = "application/octet-stream")]
		private var NormalTexture1:Class;
		
		public function Water( scene:Scene3D, gridSize:uint, planeSize:uint )
		{
			this._scene = scene;
			this._gridSize = gridSize;
			this._planeSize = planeSize;
			
			initShaders();
			initRenderables();
			initSimulation();
			updateShaderConstants();
			
			displacePoint01(0.5, 0.5, 0.1, 10.0);
		}
		
		public function get WaterPlane():Plane
		{
			return _plane;
		}
		
		public function set MirrorTexture( value:Texture3D ):void
		{
			_shader.params.ReflectionTex.value = value;
		}
		
		private function initShaders():void
		{
			//var cubemapTexture:Texture3D = new Texture3D("data/cubemap.png", false, Texture3D.FORMAT_RGBA, Texture3D.TYPE_CUBE);
			var cubemapTexture:Texture3D = new Texture3D(new CubemapTextureBytes() as ByteArray, false, Texture3D.FORMAT_RGBA, Texture3D.TYPE_CUBE);
			cubemapTexture.filterMode = Texture3D.FILTER_LINEAR;
			_shader = new FLSLMaterial("water_shader", new _shaderClass() as ByteArray);
			_shader.transparent = true;
			_shader.params.CubeTex.value = cubemapTexture;
			//
			////_shader.params.BaseColor.value[0] = 0.39; _shader.params.BaseColor.value[1] = 0.58; _shader.params.BaseColor.value[2] = 0.93; // Cornflower blue
			_shader.params.BaseColor.value[0] = 0.21; _shader.params.BaseColor.value[1] = 0.32; _shader.params.BaseColor.value[2] = 0.55; // Sea blue
			//_shader.params.BaseColor.value[0] = 0.03; _shader.params.BaseColor.value[1] = 0.52; _shader.params.BaseColor.value[2] = 0.74; // Coolwater blue
			//_shader.params.BaseColor.value[0] = 1.0; _shader.params.BaseColor.value[1] = 0.0; _shader.params.BaseColor.value[2] = 1.0; // HOT pink ;)
			//_shader.params.BaseColor.value[0] = 0.54; _shader.params.BaseColor.value[1] = 0.03; _shader.params.BaseColor.value[2] = 0.03; // Blood red
			//_shader.params.BaseColor.value[0] = 0.84; _shader.params.BaseColor.value[1] = 0.87; _shader.params.BaseColor.value[2] = 0.14; // Slime green
			//
			_shader.params.Ambient.value[0] = 0.0;
			//
			_shader.params.NormalTex1.value = new Texture3D(new NormalTexture1() as ByteArray);
			//
			_shader.build();
		}
		
		private function initRenderables():void
		{
			_plane = new Plane("WaterPlane", _planeSize, _planeSize, _gridSize-1, _shader, "+xz");
		}
		
		private function initSimulation():void
		{
			_vertexData = new Vector.<Number>();
			for ( var y:uint = 0; y < _gridSize; ++y )
			{
				for ( var x:uint = 0; x < _gridSize; ++x )
				{
					_vertexData.push(0.0, 0.0, 0.0, 0.0);
				}
			}
			
			_updateShader = new Shader(new UpdateShader() as ByteArray);
			
			_normalsShader = new Shader(new NormalsShader() as ByteArray);
			
			_dropShader = new Shader(new DropShader() as ByteArray);
			
			_waterSurface = new Surface3D("water_surface");
			_waterSurface.addVertexData(Surface3D.COLOR0, 4);
			_waterSurface.vertexVector = _vertexData;
			_waterSurface.upload(_scene);
			
			_plane.surfaces[0].sources[Surface3D.COLOR0] = _waterSurface;
		}
		
		private function runUpdateShader():void
		{
			var job:ShaderJob = new ShaderJob(_updateShader, _vertexData, _gridSize, _gridSize);
			job.start(true);
		}
		
		private function runNormalsShader():void
		{
			var job:ShaderJob = new ShaderJob(_normalsShader, _vertexData, _gridSize, _gridSize);
			job.start(true);
		}
		
		private function updateBuffers():void
		{
			if ( _waterSurface.vertexBuffer )
			{
				_waterSurface.vertexVector = _vertexData;
				_waterSurface.vertexBuffer.uploadFromVector(_vertexData, 0, _gridSize*_gridSize);
			}
		}
		
		private function updateShaderConstants():void
		{
			_updateShader.data.source.input = _vertexData;
			_updateShader.data.source.width = _gridSize;
			_updateShader.data.source.height = _gridSize;
			
			_normalsShader.data.source.input = _vertexData;
			_normalsShader.data.source.width = _gridSize;
			_normalsShader.data.source.height = _gridSize;
			
			_dropShader.data.source.input = _vertexData;
			_dropShader.data.source.width = _gridSize;
			_dropShader.data.source.height = _gridSize;
		}
		
		public function update():void
		{
			_elapsedTime += _scene.updateTime;
			runUpdateShader();
			runNormalsShader();
			updateBuffers();
			updateShaderConstants();
		}
		
		public function displacePoint01( x:Number, y:Number, radius:Number=0.03, strength:Number=0.01 ):void
		{
			// Clamp inputs.
			x = Math.max(0.0, Math.min(x, 1.0));
			y = Math.max(0.0, Math.min(y, 1.0));
			// Set shader parameters.
			_dropShader.data.GridSize.value = [_gridSize, _gridSize];
			_dropShader.data.Radius.value = [radius];
			_dropShader.data.Strength.value = [strength];
			_dropShader.data.Center.value = [x, y];
			// Run shader job.
			var job:ShaderJob = new ShaderJob(_dropShader, _vertexData, _gridSize, _gridSize);
			job.start(true);
		}
	}

}