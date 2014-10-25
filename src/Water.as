package  
{
	import flare.basic.Scene3D;
	import flare.core.Surface3D;
	import flare.core.Texture3D;
	import flare.flsl.FLSLMaterial;
	import flare.primitives.Plane;
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.display.ShaderJob;
	import flash.geom.Point;
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
		private var _vertexData:ByteArray; /**< Raw vertex data. */
		private var _waterBitmap:BitmapData; /**< The 2d image resulting from the ShaderJob computation. */
		[Embed(source = "/../bin/data/water_update.pbj", mimeType = "application/octet-stream")]
		private var UpdateShader:Class;
		private var _updateShader:Shader; /**< Computation shader for waves. */
		private var p0:Point = new Point();
		private var p1:Point = new Point();
		
		// -*- Materials -*-
		[Embed(source = "/../bin/data/water.flsl.compiled", mimeType = "application/octet-stream")]
		private var _shaderClass:Class;
		private var _shader:FLSLMaterial; /**< Shader for the water. */
		
		// -*- Renderables -*-
		private var _plane:Plane;    /**< Final rendererd geometry. */
		private var _planeSize:uint; /**< Size of the plane geometry. */
		
		public function Water( scene:Scene3D, gridSize:uint, planeSize:uint )
		{
			this._scene = scene;
			this._gridSize = gridSize;
			this._planeSize = planeSize;
			
			initShaders();
			initRenderables();
			initSimulation();
		}
		
		public function get WaterPlane():Plane
		{
			return _plane;
		}
		
		private function initShaders():void
		{
			_shader = new FLSLMaterial("water_shader", new _shaderClass() as ByteArray);
			_shader.params.CubeTex.value = new Texture3D("data/highlights.png", false, Texture3D.FORMAT_RGBA, Texture3D.TYPE_CUBE);
			_shader.params.NormalTex.value = new Texture3D("data/normalMap.jpg");
			//
			_shader.params.WaveScale.value[0] = 3.0;
			//
			_shader.params.BaseColor.value[0] = 0.39;
			_shader.params.BaseColor.value[1] = 0.58;
			_shader.params.BaseColor.value[2] = 0.93;
			_shader.params.BaseColor.value[3] = 1.0;
			//
			_shader.params.Ambient.value[0] = 0.2;
			
		}
		
		private function initRenderables():void
		{
			_plane = new Plane("WaterPlane", _planeSize, _planeSize, _gridSize-1, _shader, "+xz");
		}
		
		private function initSimulation():void
		{
			_vertexData = new ByteArray();
			_vertexData.endian = Endian.LITTLE_ENDIAN;
			_vertexData.length = _gridSize * _gridSize * 12; // 4 bytes * RGB = 12
			
			_waterBitmap = new BitmapData(_gridSize, _gridSize, false);
			
			_updateShader = new Shader(new UpdateShader() as ByteArray);
			_updateShader.data.source.input = _waterBitmap;
			
			_waterSurface = new Surface3D("water_surface");
			_waterSurface.addVertexData(Surface3D.COLOR0, 3);
			_waterSurface.vertexBytes = _vertexData;
			_waterSurface.upload(_scene);
			
			_plane.surfaces[0].sources[Surface3D.COLOR0] = _waterSurface;
		}
		
		private function runUpdateShader():void
		{
			var timer:int = getTimer();
			p0.y = timer / 400;
			p1.y = timer / 640;
			_waterBitmap.perlinNoise(3, 3, 2, 0, false, true, 7, true, [p0, p1]);
			
			var job:ShaderJob = new ShaderJob(_updateShader, _vertexData, _gridSize, _gridSize);
			job.start(true);
		}
		
		private function updateBuffers():void
		{
			if ( _waterSurface.vertexBuffer )
			{
				_waterSurface.vertexBuffer.uploadFromByteArray(_vertexData, 0, 0, _gridSize * _gridSize);
			}
		}
		
		public function update():void
		{
			runUpdateShader();
			updateBuffers();
		}
	}

}