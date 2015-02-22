package {

	import flash.display.*;
	import flash.utils.*;
	import flash.events.*;
	import flash.ui.*;
	import flash.geom.*;
	import flash.media.*;
	import flash.external.ExternalInterface;

	public class WalkCursor extends Sprite {
		//歩行モード
		private const LEFT:int=1;
		private const RIGHT:int=2;
		private var prevBtn : int = RIGHT;  //最後に押したボタン
		
		//背景モード
		private const MODE_NORMAL : int = 1;
		private const MODE_GRASS : int = 2;
		private const MODE_SNOW : int = 3;
		private const MODE_FLOWER : int = 4;
		private const MODE_LEAVES : int = 5;
		private var backMode = MODE_NORMAL;

		//移動速度（単位：ピクセル）
		public const SPEED_WALK : int = 30;
		public const SPEED_DASH : int = 100;
		private var walkSpeed : int = SPEED_WALK;

		//ダッシュ判定間隔（単位：ミリ秒）
		private const INTERVAL_DASH : int = 200;
		
		//操作対象オブジェクト指定変数
		private var mc_Hito : MovieClip;  //カーソル
		private var mc_Back : MovieClip;  //背景
		private var mc_SpecialBack : MovieClip;  //特殊背景
		private var mc_Mask : MovieClip;  //マスク
		private var maskDScale : Number = 1;  //マスクの拡大率
		private var target_btn : Object;  //押したボタンへの参照
		private var se : Object;  //落葉の効果音
		
		private var prevPos : Point = new Point();//1フレーム前のカーソル座標
		private var prevClickTime : int = -1000;//最後にクリックした時間
		
		private var leftBtnFlag : Boolean = false;  //左ボタンを押しているか
		private var rightBtnFlag : Boolean = false;  //右ボタンを押しているか
		
		public var actionFlag : Boolean = false;  //アクション中かどうか

		//コンストラクタ
		public function WalkCursor() {
			//Flashの設定
			stage.scaleMode=StageScaleMode.NO_SCALE;
			stage.align=StageAlign.TOP_LEFT;

			//動かす人・背景の設定
			mc_Hito = hito;
			mc_Back = back;
			mc_SpecialBack = back_grass;
			mc_Mask = circleMask;
			mc_Hito.mouseEnabled = false;
			mc_Hito.mouseChildren = false;
			
			//マウスカーソルの変更
			stage.addEventListener( MouseEvent.MOUSE_MOVE, moveCursor );
			var timer : Timer = new Timer( 120 );
			timer.addEventListener( TimerEvent.TIMER, changeCursorDirection );
			timer.start();
			Mouse.hide();

			//常に行う判定
			stage.addEventListener( Event.ENTER_FRAME, onFrame );

			//マウス左ボタンイベント登録
			ExternalInterface.addCallback("leftMouseDown", onLeftMouseDown);
			ExternalInterface.addCallback("leftMouseUp", onLeftMouseUp);
			//マウス右ボタンイベント登録
			ExternalInterface.addCallback("rightMouseDown", onRightMouseDown);
			ExternalInterface.addCallback("rightMouseUp", onRightMouseUp);
			
			//背景ボタンイベント登録
			mc_Back.grass_btn.addEventListener( MouseEvent.CLICK, changeGrassMode );
			mc_Back.snow_btn.addEventListener( MouseEvent.CLICK, changeSnowMode );
			mc_Back.flower_btn.addEventListener( MouseEvent.CLICK, changeFlowerMode );
			mc_Back.leaves_btn.addEventListener( MouseEvent.CLICK, changeLeavesMode );
			mc_Back.normal_btn.addEventListener( MouseEvent.CLICK, changeNormalMode );
			
			//効果音の準備
			se = new Oto();
			
			//カーソル位置
			prevPos.x=mc_Hito.x;
			prevPos.y=mc_Hito.y;
		}

		//カーソルをマウスに追随
		private function moveCursor( e : MouseEvent ) {
			//アクション中は追随しない
			if (actionFlag==true) {
				return;
			}
			//カーソル位置
			mc_Hito.x=stage.mouseX;
			mc_Hito.y=stage.mouseY;
			e.updateAfterEvent();
		}
		
		//カーソルの向きを変える
		private function changeCursorDirection( e : TimerEvent ) : void {
			//カーソル向き
			if ( (mc_Hito.x != prevPos.x) && (mc_Hito.y != prevPos.y) ) {
				var dx : Number = mc_Hito.x - prevPos.x;
				var dy : Number = mc_Hito.y - prevPos.y;
				var radian : Number = Math.atan2( dy, dx );
				var rot : Number = radian * (180 / Math.PI );
				if ( backMode == MODE_NORMAL ) {  //通常時は上下移動のみ
					if ( rot >= -180 && rot <= 0 ) {  //上
						rot = -90;
					} else if ( rot > 0 && rot < 180 ) {  //下
						rot = 90;
					}
				}
				if ( (backMode != MODE_NORMAL) || (getSpeed() == SPEED_WALK) ) {
					mc_Hito.rotation = rot + 90;
				}
			}
			prevPos.x = mc_Hito.x;
			prevPos.y = mc_Hito.y;
		}
		
		//毎フレーム行う処理（衝突判定など）
		private function onFrame( e : Event ) : void {
			//アクション中なら何もしない
			if (actionFlag==true) {
				return;
			}
			
			//通常時
			if ( (leftBtnFlag == false) && (rightBtnFlag == false) ) {
				mc_Hito.gotoAndStop("静止");
			}
			
			//ボタン上
			if ( mc_Back.normal_btn.hitTestPoint( stage.mouseX, stage.mouseY ) ||
				 mc_Back.grass_btn.hitTestPoint( stage.mouseX, stage.mouseY ) ||
				 mc_Back.snow_btn.hitTestPoint( stage.mouseX, stage.mouseY ) ||
				 mc_Back.flower_btn.hitTestPoint( stage.mouseX, stage.mouseY ) ||
				 mc_Back.leaves_btn.hitTestPoint( stage.mouseX, stage.mouseY ) )
			{
				mc_Hito.gotoAndStop( "歩き右" );
			}
		}
		
		//背景モード変更
		private function changeMode() : void {
			mc_SpecialBack.x = mc_Back.x - 1000;
			mc_SpecialBack.y = mc_Back.y - 150;
			mc_SpecialBack.mask = mc_Mask;
			
			mc_Back.addEventListener( Event.ENTER_FRAME, maskBack );
		}
		
		//草原モードに変更
		private function changeGrassMode( e : MouseEvent ) : void {
			initBack();
			backMode = MODE_GRASS;
			mc_SpecialBack = back_grass;
			target_btn = mc_Back.grass_btn;
			changeMode();
		}
		
		//雪原モードに変更
		private function changeSnowMode( e : MouseEvent ) : void {
			initBack();
			backMode = MODE_SNOW;
			mc_SpecialBack = back_snow;
			target_btn = mc_Back.snow_btn;
			changeMode();
		}
		
		//花畑モードに変更
		private function changeFlowerMode( e : MouseEvent ) : void {
			initBack();
			backMode = MODE_FLOWER;
			mc_SpecialBack = back_flower;
			target_btn = mc_Back.flower_btn;
			changeMode();
		}
		
		//落ち葉モードに変更
		private function changeLeavesMode( e : MouseEvent ) : void {
			initBack();
			backMode = MODE_LEAVES;
			mc_SpecialBack = back_leaves;
			target_btn = mc_Back.leaves_btn;
			changeMode();
		}
		
		//通常モードに変更
		private function changeNormalMode( e : MouseEvent ) : void {
			if ( backMode == MODE_NORMAL ) {
				return;
			}
			mc_Back.removeEventListener( Event.ENTER_FRAME, maskBack );
			backMode = MODE_NORMAL;
			mc_Back.x = 0;
			mc_Back.addEventListener( Event.ENTER_FRAME, resetBackMode );
		}
		
		//背景の初期化
		private function initBack() : void {
			mc_Back.removeEventListener( Event.ENTER_FRAME, maskBack );
			mc_Back.removeEventListener( Event.ENTER_FRAME, resetBackMode );
			back_grass.alpha = 0;
			back_snow.alpha = 0;
			back_flower.alpha = 0;
			back_leaves.alpha = 0;
			mc_Mask.scaleX = mc_Mask.scaleY = 1;
			mc_Mask.x = mc_Mask.y = -500;
			maskDScale = 1;
		}
		
		//背景のフェードイン
		private function maskBack( e : Event ) : void {
			var pos : Point = new Point( target_btn.x, target_btn.y );
			pos = mc_Back.localToGlobal( pos );
			mc_Mask.x = pos.x;
			mc_Mask.y = pos.y;
			
			//特殊背景のフェードイン
			mc_SpecialBack.alpha += 0.08;
			if ( mc_SpecialBack.alpha > 1 ) {
				mc_SpecialBack.alpha = 1;
			}
			//特殊背景のマスク拡大処理
			mc_Mask.scaleX = mc_Mask.scaleY *= maskDScale;
			maskDScale += 0.05;
			if ( mc_Mask.width > 5000  && mc_SpecialBack.alpha >= 1) {
				maskDScale = 1;
				mc_Back.removeEventListener( Event.ENTER_FRAME, maskBack );
			}
		}
		
		//通常状態に戻す
		private function resetBackMode( e : Event ) : void {
			var pos : Point = new Point( target_btn.x, target_btn.y );
			pos = mc_Back.localToGlobal( pos );
			mc_Mask.x = pos.x;
			mc_Mask.y = pos.y;
			
			mc_SpecialBack.alpha -= 0.02;
			//特殊背景のマスク縮小処理
			mc_Mask.scaleX = mc_Mask.scaleY *= 0.6;
			if ( mc_Mask.width < 100 ) {
				initBack();
			}
		}
		
		//左ボタンを押したときの処理
		private function onLeftMouseDown() : void {
			var mx : int = stage.mouseX;
			var my : int = stage.mouseY;
			if ( my > 0 && my < stage.stageHeight && mx > 0 && mx < stage.stageWidth ) {
				//ここに処理を書く

				//アクション中なら何もしない
				if ( actionFlag == true ) {
					return;
				}
				//一歩前が左足の場合はモーションのみ
				if ( prevBtn == LEFT ) {
					leftEffect();
					mc_Hito.gotoAndStop( "歩き左" );
					leftBtnFlag = true;
					return;
				}
				//ボタン上では進まない
				if ( mc_Back.normal_btn.hitTestPoint( stage.mouseX, stage.mouseY ) ||
				 	 mc_Back.grass_btn.hitTestPoint( stage.mouseX, stage.mouseY ) ||
				 	 mc_Back.snow_btn.hitTestPoint( stage.mouseX, stage.mouseY ) ||
				 	 mc_Back.flower_btn.hitTestPoint( stage.mouseX, stage.mouseY ) ||
				 	 mc_Back.leaves_btn.hitTestPoint( stage.mouseX, stage.mouseY ) )
				{
					return;
				}

				//歩行モーション
				leftEffect();
				mc_Hito.gotoAndStop( "歩き左" );
				//移動
				move();
				
				//最後にクリックしたボタン・時間の取得
				prevBtn = LEFT;
				prevClickTime = getTimer();
				leftBtnFlag = true;
			}
		}

		//左ボタンを離したときの処理
		private function onLeftMouseUp() : void {
			var mx : int = stage.mouseX;
			var my : int = stage.mouseY;
			if ( my > 0 && my < stage.stageHeight && mx > 0 && mx < stage.stageWidth ) {
				//ここに処理を書く
				leftBtnFlag = false;
			}
		}

		//右ボタンを押したときの処理
		private function onRightMouseDown() : void {
			var mx : int = stage.mouseX;
			var my : int = stage.mouseY;
			if ( my > 0 && my < stage.stageHeight && mx > 0 && mx < stage.stageWidth ) {
				//ここに処理を書く

				//アクション中なら何もしない
				if ( actionFlag == true ) {
					return;
				}
				//一歩前が右足の場合はモーションのみ
				if ( prevBtn == RIGHT ) {
					rightEffect();
					mc_Hito.gotoAndStop( "歩き右" );
					rightBtnFlag = true;
					return;
				}
				//ボタン上では進まない
				if ( mc_Back.normal_btn.hitTestPoint( stage.mouseX, stage.mouseY ) ||
				 	 mc_Back.grass_btn.hitTestPoint( stage.mouseX, stage.mouseY ) ||
				 	 mc_Back.snow_btn.hitTestPoint( stage.mouseX, stage.mouseY ) ||
				 	 mc_Back.flower_btn.hitTestPoint( stage.mouseX, stage.mouseY ) ||
				 	 mc_Back.leaves_btn.hitTestPoint( stage.mouseX, stage.mouseY ) )
				{
					return;
				}
				
				//歩行モーション
				rightEffect();
				mc_Hito.gotoAndStop( "歩き右" );
				//移動
				move();

				//最後にクリックしたボタン・時間の取得
				prevBtn = RIGHT;
				prevClickTime=getTimer();
				rightBtnFlag = true;
			}
		}

		//右ボタンを離したときの処理
		private function onRightMouseUp() : void {
			var mx : int = stage.mouseX;
			var my : int = stage.mouseY;
			if ( my > 0 && my < stage.stageHeight && mx > 0 && mx < stage.stageWidth ) {
				//ここに処理を書く
				rightBtnFlag = false;
			}
		}

		//背景を動かして移動する
		private function move() : void {
			walkSpeed = getSpeed();  //移動速度
			var rot : Number = mc_Hito.rotation + 90;  //角度
			var dx : Number = Math.cos( rot * Math.PI / 180 ) * walkSpeed;  //x移動量
			var dy : Number = Math.sin( rot * Math.PI / 180 ) * walkSpeed;  //y移動量
			
			//背景移動
			mc_Back.x += dx;
			mc_Back.y += dy;
			
			if ( ( mc_Back.y + mc_Back.height ) < stage.stageHeight ) {  //下端
				mc_Back.y = stage.stageHeight - mc_Back.height;
			}
			if ( mc_Back.y > 150 ) {  //上端
				mc_Back.y = 150;
			}
			if ( ( mc_Back.x + mc_Back.width ) < stage.stageWidth ) {  //右端
				mc_Back.x = stage.stageWidth - mc_Back.width;
			}
			if ( mc_Back.x > 1000 ) {  //左端
				mc_Back.x = 1000;
			}
			
			//特殊背景の移動
			if ( backMode != MODE_NORMAL ) {
				mc_SpecialBack.x += dx;
				mc_SpecialBack.y += dy;
				if ( ( mc_SpecialBack.y + mc_SpecialBack.height ) < stage.stageHeight ) {  //下端
					mc_SpecialBack.y = stage.stageHeight - mc_SpecialBack.height;
				}
				if ( mc_SpecialBack.y > 0 ) {  //上端
					mc_SpecialBack.y = 0;
				}
				if ( ( mc_SpecialBack.x + mc_SpecialBack.width ) < stage.stageWidth ) {  //右端
					mc_SpecialBack.x = stage.stageWidth - mc_SpecialBack.width;
				}
				if ( mc_SpecialBack.x > 0 ) {  //左端
					mc_SpecialBack.x = 0;
				}
			}
		}

		//現在の移動速度を取得する
		public function getSpeed() : int {
			var speed : int = 0;
			var time : int = getTimer() - prevClickTime;  //クリック時間差（単位：ミリ秒）
			
			if ( time < INTERVAL_DASH ) {
				speed = SPEED_DASH;
			} else {
				speed = SPEED_WALK;
			}
			return speed;
		}
		
		private function leftEffect() : void {
			//雪原の足跡
			if ( backMode == MODE_SNOW ) {
				var fp : MovieClip = new FootPrint();
				fp.x = mc_SpecialBack.mouseX;
				fp.y = mc_SpecialBack.mouseY;
				mc_SpecialBack.addChild( fp );
			}
			//花畑で散る花
			if ( backMode == MODE_FLOWER ) {
				var petal : MovieClip = new Petal();
				petal.x = mc_SpecialBack.mouseX;
				petal.y = mc_SpecialBack.mouseY;
				petal.rotation = mc_Hito.rotation;
				mc_SpecialBack.addChild( petal );
			}
			//落葉の音
			if ( backMode == MODE_LEAVES ) {
				se.play();
			}
		}
		
		private function rightEffect() : void {
			var pos : Point = new Point( mc_Hito.nakayubi.x, mc_Hito.nakayubi.y );
			pos = mc_Hito.localToGlobal( pos );
			pos = stage.localToGlobal( pos );
			//雪原の足跡
			if ( backMode == MODE_SNOW ) {
				var fp : MovieClip = new FootPrint();
				pos = mc_SpecialBack.globalToLocal( pos );
				fp.x = pos.x;
				fp.y = pos.y;
				mc_SpecialBack.addChild( fp );
			}
			//花畑で散る花
			if ( backMode == MODE_FLOWER ) {
				var petal : MovieClip = new Petal();
				pos = mc_SpecialBack.globalToLocal( pos );
				petal.x = pos.x;
				petal.y = pos.y;
				petal.rotation = mc_Hito.rotation;
				mc_SpecialBack.addChild( petal );
			}
			//落葉の音
			if ( backMode == MODE_LEAVES ) {
				se.play();
			}
		}
		
		//デバッグ用関数
		public static function alert( mesg : * ) : void {
			if ( ExternalInterface.available ) {
				ExternalInterface.call( 'alert', String(mesg) );
			} else {
				trace( String(mesg) );
			}
		}
	}
}
