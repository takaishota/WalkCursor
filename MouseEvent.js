flag_rightDown = false;

var MouseEvent = {
	/**
	 *  Constructor
	 */ 
	init: function () {
		this.FlashObjectID = "customMouseEvent";
		this.FlashContainerID = "flashcontent";
		this.Cache = this.FlashObjectID;
		if(window.addEventListener){
			 window.addEventListener("mousedown", this.onGeckoMouseDown(), true);
			 window.addEventListener("mouseup", this.onGeckoMouseUp(), true);
		} else {
			document.getElementById(this.FlashContainerID).onmouseup = MouseEvent.onIEMouseUp;
			document.oncontextmenu = function(){ if(window.event.srcElement.id == MouseEvent.FlashObjectID) { return false; } else { MouseEvent.Cache = "nan"; }}
			document.getElementById(this.FlashContainerID).onmousedown = MouseEvent.onIEMouseDown;
		}
	},
	/**
	 *  Disable the Right-Click event trap  and continue showing flash player menu
	 */ 
	UnInit: function () { 
	    //alert('Un init is called' );			
		if(window.RemoveEventListener){
			alert('Un init is called for GECKO' );			
			window.addEventListener("mousedown", null, true);
			window.RemoveEventListener("mousedown",this.onGeckoMouse(),true);
			window.RemoveEventListener("mouseup",this.onGeckoMouse(),true);
			 //window.releaseEvents("mousedown");
		} else {
			//alert('Un init is called for IE' );							
			document.getElementById(this.FlashContainerID).onmouseup = "" ;
			document.oncontextmenu = "";
			document.getElementById(this.FlashContainerID).onmousedown = "";
		}
	},

	/**
	 * GECKO / WEBKIT event overkill
	 * @param {Object} eventObject
	 */
	killEvents: function(eventObject) {
		if(eventObject) {
			if (eventObject.stopPropagation) eventObject.stopPropagation();
			if (eventObject.preventDefault) eventObject.preventDefault();
			if (eventObject.preventCapture) eventObject.preventCapture();
	   		if (eventObject.preventBubble) eventObject.preventBubble();
		}
	},
	/**
	 * GECKO / WEBKIT call right click
	 * @param {Object} ev
	 */
	onGeckoMouseDown: function(ev) {
	  	return function(ev) {
		if (ev.button == 0) {  //マウス左
			if(ev.target.id == MouseEvent.FlashObjectID && MouseEvent.Cache == MouseEvent.FlashObjectID) {
				MouseEvent.callLeftDown();
			}
			MouseEvent.Cache = ev.target.id;
		}
		else if (ev.button != 0) {  //マウス右
			MouseEvent.killEvents(ev);
			if(ev.target.id == MouseEvent.FlashObjectID && MouseEvent.Cache == MouseEvent.FlashObjectID) {
	    		MouseEvent.callRightDown();
			}
			MouseEvent.Cache = ev.target.id;
		}
	  }
	},
	onGeckoMouseUp: function(ev) {
	  	return function(ev) {
		if (ev.button == 0) {  //マウス左
			if(ev.target.id == MouseEvent.FlashObjectID && MouseEvent.Cache == MouseEvent.FlashObjectID) {
				MouseEvent.callLeftUp();
			}
		}
		else if (ev.button != 0) {  //マウス右
	    	if(ev.target.id == MouseEvent.FlashObjectID && MouseEvent.Cache == MouseEvent.FlashObjectID) {
	    		MouseEvent.callRightUp();
			}
		}
	  }
	},
	/**
	 * IE call right click
	 * @param {Object} ev
	 */
	onIEMouseDown: function() {
		if ( (event.button == 1) || (event.button == 3 && flag_rightDown == true) ) {  //マウス左
			if(window.event.srcElement.id == MouseEvent.FlashObjectID && MouseEvent.Cache == MouseEvent.FlashObjectID) {
				MouseEvent.callLeftDown();
			}
		}
	  	else if ( (event.button == 2) || (event.button == 3 && flag_rightDown == false) ) {  //マウス右
			if(window.event.srcElement.id == MouseEvent.FlashObjectID && MouseEvent.Cache == MouseEvent.FlashObjectID) {
				MouseEvent.callRightDown();
				flag_rightDown = true;
			}
			document.getElementById(MouseEvent.FlashContainerID).setCapture();
			if(window.event.srcElement.id) {
				MouseEvent.Cache = window.event.srcElement.id;
			}
		}
	},
	onIEMouseUp: function() {
		document.getElementById(MouseEvent.FlashContainerID).releaseCapture();
		if (event.button == 1) {  //マウス左
			if(window.event.srcElement.id == MouseEvent.FlashObjectID && MouseEvent.Cache == MouseEvent.FlashObjectID) {
				MouseEvent.callLeftUp();
			}
		}
		else if (event.button == 2) {  //マウス右
			if(window.event.srcElement.id == MouseEvent.FlashObjectID && MouseEvent.Cache == MouseEvent.FlashObjectID) {
				MouseEvent.callRightUp();
				flag_rightDown = false;
			}
		}
	},
	/**
	 * Main call to Flash External Interface
	 */
	callLeftDown: function() {
		document.getElementById(this.FlashObjectID).leftMouseDown();
	},
	callLeftUp: function() {
		document.getElementById(this.FlashObjectID).leftMouseUp();
	},
	callRightDown: function() {
		document.getElementById(this.FlashObjectID).rightMouseDown();
	},
	callRightUp: function() {
		document.getElementById(this.FlashObjectID).rightMouseUp();
	}
}