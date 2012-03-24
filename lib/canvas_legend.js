function draw_canvas_legend(canvas_id, colorbar, legend_min, legend_max, leg_dec_places, vardesc_txt) {
    var colorbar_img_path = "colorbars/" + colorbar + ".png";
    var canvas_element = document.getElementById(canvas_id);
    var legend_range = legend_max - legend_min;
    var num_ticks = 11;
    var legend_tick = legend_range / (num_ticks - 1);
    var leg_dec_mul = Math.pow(10, leg_dec_places);
    var leg_offset_x = 15;
    var leg_offset_y = 5;

    if(canvas_element.getContext) {
	var ctx = canvas_element.getContext('2d');
	var colorbar_img = new Image();
	colorbar_img.src = colorbar_img_path;
	colorbar_img.onload = function() {
	    ctx.drawImage(colorbar_img, leg_offset_x, leg_offset_y);
	    ctx.strokeStyle = "#000000";
	    ctx.lineWidth = "1px";
	    ctx.lineCap = "square";
	    ctx.strokeRect(leg_offset_x - 0.5, leg_offset_y - 0.5, colorbar_img.width + 1, colorbar_img.height + 1);
	    var legend_val = legend_min;
	    var tick_spacing = (colorbar_img.width + 1) / (num_ticks - 1);
	    var legend_pos = 0;
	    ctx.textBaseline = "top";
	    ctx.textAlign = "center";
	    ctx.font = "10px verdana, arial, sans-serif";
	    for(i = 0; i < num_ticks; i++) {
		var tick_y = leg_offset_y + colorbar_img.height + 1;
		var tick_x = Math.round(leg_offset_x + tick_spacing * i) - 0.5;
		var tick_label = Math.round(leg_dec_mul * legend_tick * i) / leg_dec_mul + legend_min;
		draw_line(ctx, tick_x, tick_y - 3, tick_x, tick_y + 3);
		ctx.fillText(tick_label, tick_x, tick_y + 5);
	    }
	    ctx.fillText(vardesc_txt, colorbar_img.width / 2 + leg_offset_x, leg_offset_y + colorbar_img.height + 18);
	}
    } else {
	alert("Your browser does not support HTML CANVAS. You will not have a legend. Have a nice day!");
    }
}

function draw_line(ctx, start_x, start_y, end_x, end_y) {
    ctx.beginPath();
    ctx.moveTo(start_x, start_y);
    ctx.lineTo(end_x, end_y);
    ctx.stroke();
}