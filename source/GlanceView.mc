using Toybox.WatchUi;

(:glance)
class MyGlanceView extends WatchUi.GlanceView
{

    function initialize() {
        GlanceView.initialize();    	         
    }
    
    function onUpdate(dc) {
		dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
		dc.clear();
		dc.setColor(Graphics.COLOR_ORANGE,Graphics.COLOR_TRANSPARENT);

		dc.drawText(dc.getWidth()/2, 5, Graphics.FONT_TINY,"Reading Monkey", Graphics.TEXT_JUSTIFY_CENTER);
    } 
}
