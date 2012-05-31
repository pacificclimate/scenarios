function draw_raphael_legend(r_id, colorbar, legend_min, legend_max, leg_dec_places, vardesc_txt) {
    var colorbar_img_path = "img/colorbars/" + colorbar + ".png";
    var r_div = document.getElementById(r_id);
    var r = Raphael(r_id, 670, 53);
    var legend_range = legend_max - legend_min;
    var num_ticks = 11;
    var legend_tick = legend_range / (num_ticks - 1);
    var leg_dec_mul = Math.pow(10, leg_dec_places);
    var leg_offset_x = 20;
    var leg_offset_y = 1;
    var text_attrs = { fill: "#000000", font: "11px verdana, arial, sans-serif" };
    var line_attrs = { stroke: "#000000", "stroke-linecap": "square" };

    var colorbar_img = r.image(colorbar_img_path, leg_offset_x - 0.5, leg_offset_y - 0.5, 630, 22);
    var cb_size = colorbar_img.getBBox();
    var cb_height = cb_size.height;
    var cb_width = cb_size.width;
    var colorbar_box = r.rect(leg_offset_x - 0.5, leg_offset_y - 0.5, cb_width, cb_height);
    colorbar_box.attr(line_attrs);

    var tick_spacing = (cb_width) / (num_ticks - 1);
    for(i = 0; i < num_ticks; i++) {
	var tick_y = leg_offset_y + cb_height + 1;
	var tick_x = Math.round(leg_offset_x + tick_spacing * i) - 0.5;
	var tick_label = Math.round(leg_dec_mul * legend_tick * i) / leg_dec_mul + legend_min;
	var tick = r.path("M" + tick_x + "," + (tick_y - 3) + "L" + tick_x + "," + (tick_y + 3));
	var leg_text = r.text(tick_x, tick_y + 10, tick_label);
	//ctx.textBaseline = "top";
	leg_text.attr(text_attrs);
	tick.attr(line_attrs);
    }
    var label_text = r.text(cb_width / 2 + leg_offset_x, leg_offset_y + cb_height + 23, vardesc_txt);
    label_text.attr(text_attrs);
}
