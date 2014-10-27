package
{
	import flare.basic.*;
	import flare.collisions.MouseCollision;
	import flare.core.*;
	import flare.events.*;
	import flare.materials.*;
	import flare.materials.filters.*;
	import flare.physics.colliders.BoxCollider;
	import flare.physics.colliders.Collider;
	import flare.physics.colliders.MeshCollider;
	import flare.physics.Contact;
	import flare.primitives.*;
	import flare.system.Input3D;
	import flash.display.*;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Vector3D;
	import flash.utils.Timer;
	
	public class Main extends Sprite
	{
		private var _scene:Scene3D;
		private var _skybox:SkyBox;
		private var _water:Water;
		private var _rainTimer:Timer;
		//
		private var _mouseCollider:MouseCollision;
		
		public function Main():void
		{
			_scene = new Viewer3D(this, "", 0.2);
			_scene.autoResize = true;
			_scene.camera.setPosition(120, 40, -30);
			_scene.camera.lookAt(0, 0, 0);
			
			_skybox = new SkyBox("data/cubemap.png", SkyBox.HORIZONTAL_CROSS, null, 1.0);
			_scene.addChild(_skybox);
			
			_water = new Water(_scene, 200, 200);
			_water.WaterPlane.useHandCursor = true;
			_water.WaterPlane.mouseEnabled = true;
			//_water.WaterPlane.addEventListener(MouseEvent3D.CLICK, onPlaneMouseMove);
			//_water.WaterPlane.addEventListener(MouseEvent3D.MOUSE_MOVE, onPlaneMouseMove);
			_scene.addChild(_water.WaterPlane);
			
			_scene.addEventListener(Scene3D.UPDATE_EVENT, onUpdate);
			_scene.addEventListener(Scene3D.RENDER_EVENT, onRender);
			
			_rainTimer = new Timer(100, 0);
			_rainTimer.addEventListener(TimerEvent.TIMER, onRain);
			_rainTimer.start();
			
			_mouseCollider = new MouseCollision(_scene.camera);
			_mouseCollider.addCollisionWith(_water.WaterPlane);
		}
		
		private function onUpdate( e:Event ):void
		{
			var cols:Boolean = _mouseCollider.test(Input3D.mouseX, Input3D.mouseY);
			if ( cols )
			{
				var u:Number = _mouseCollider.data[0].u;
				var v:Number = _mouseCollider.data[0].v;
				_water.displacePoint01(1.0 - u, 1.0 - v, 0.03, 1.5);
			}
			
			_water.update();
		}
		
		private function onRender( e:Event ):void
		{
		}
		
		//private function onPlaneMouseMove( evt:MouseEvent3D ):void
		//{
			//_water.displacePoint01(1.0 - evt.info.u, 1.0 - evt.info.v, 0.03, 1.5);
		//}
		
		private function onRain( evt:TimerEvent ):void
		{
			var random_x:Number = Math.random();
			var random_y:Number = Math.random();
			_water.displacePoint01(random_x, random_y, 0.01, 4.0);
		}
	}
}