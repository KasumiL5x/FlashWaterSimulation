package
{
	import flare.basic.*;
	import flare.core.*;
	import flare.events.*;
	import flare.materials.*;
	import flare.materials.filters.*;
	import flare.primitives.*;
	import flash.display.*;
	import flash.events.Event;
	
	public class Main extends Sprite
	{
		private var _scene:Scene3D;
		private var _skybox:SkyBox;
		private var _water:Water;
		
		public function Main():void
		{
			_scene = new Viewer3D(this);
			_scene.autoResize = true;
			_scene.camera.setPosition(120, 40, -30);
			_scene.camera.lookAt(0, 0, 0);
			
			_skybox = new SkyBox("data/sky.png", SkyBox.HORIZONTAL_CROSS, null, 1.0);
			_scene.addChild(_skybox);
			
			_water = new Water(_scene, 64, 150);
			_scene.addChild(_water.WaterPlane);
			
			_scene.addEventListener(Scene3D.UPDATE_EVENT, onUpdate);
			_scene.addEventListener(Scene3D.RENDER_EVENT, onRender);
		}
		
		private function onUpdate( e:Event ):void
		{
			_water.update();
		}
		
		private function onRender( e:Event ):void
		{
		}
	}
}