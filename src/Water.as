package  
{
	import flare.flsl.FLSLMaterial;
	import flare.primitives.Plane;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Daniel Green
	 */
	public class Water 
	{
		// -*- Simulation properties -*-
		private var _gridSize:uint; /**< Simulation grid size. */
		
		// -*- Materials -*-
		[Embed(source = "/../bin/data/water.flsl.compiled", mimeType = "application/octet-stream")]
		private var _shaderClass:Class;
		private var _shader:FLSLMaterial; /**< Shader for the water. */
		
		// -*- Renderables -*-
		private var _plane:Plane;    /**< Final rendererd geometry. */
		private var _planeSize:uint; /**< Size of the plane geometry. */
		
		public function Water( gridSize:uint, planeSize:uint )
		{
			this._gridSize = gridSize;
			this._planeSize = planeSize;
			
			initShaders();
			initRenderables();
		}
		
		public function get WaterPlane():Plane
		{
			return _plane;
		}
		
		private function initShaders():void
		{
			_shader = new FLSLMaterial("water_shader", new _shaderClass() as ByteArray);
		}
		
		private function initRenderables():void
		{
			_plane = new Plane("WaterPlane", _planeSize, _planeSize, _gridSize-1, _shader, "+xz");
		}
		
	}

}