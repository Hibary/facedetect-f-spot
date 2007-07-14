#include "f-image-view.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <float.h>
#include <limits.h>
#include <time.h>
#include <ctype.h>

#ifdef _EiC
#define WIN32
#endif




//int detect_ada(char *pixbuf, int w, int h, int r, int n);

int is_equal(GdkRectangle *r1, GdkRectangle *r2, double xf, double yf) {
//	printf("%d=%d, %d=%d, %d=%d, %d=%d\n",r1.x, r2.x, r1.y, r2.y, r1.width,r2.width, r1.height, r2.height);
	double distance = r1->width * 0.2;
	return r2->x <= r1->x + distance &&
           r2->x >= r1->x - distance &&
           r2->y <= r1->y + distance &&
           r2->y >= r1->y - distance &&
           r2->width <= cvRound( r1->width * 1.2 ) &&
           cvRound( r2->width * 1.2 ) >= r1->width;

}

int is_inner(GdkRectangle r1, GdkRectangle r2, double xf, double yf) {
	
	return (r1.x <= r2.x && r1.y <= r2.y &&
			r1.height > r2.height && r1.width > r2.width) ? 1 : 0;
	
}
void draw_box (FImageView *image_view, GdkRegion *other, GdkRectangle r, double xf, double yf) {
		
		GdkRectangle zone;
		int x1, x2, y1, y2;
		x1 = r.x ;
	    x2 = x1 + r.width ;
	    y1 = r.y ;
	    y2 = y1 + r.height;

	    image_coords_to_window(image_view, x1, y1, &x1, &y1);
	    image_coords_to_window(image_view, x2, y2, &x2, &y2);
	    // top line
	    zone.x = x1;
	    zone.y = y1;
	    zone.width = x2 - x1;
	    zone.height = 1;
	    gdk_region_union_with_rect (other, &zone);
	    // left line
	    zone.x = x1;
	    zone.y = y1;
	    zone.width = 1;
	    zone.height = y2 - y1;
	    gdk_region_union_with_rect (other, &zone);
	    // bottom line
	    zone.x = x1;
	    zone.y = y2;
	    zone.width = x2 - x1;
	    zone.height = 1;
	    gdk_region_union_with_rect (other, &zone);
	    // right line
	    zone.x = x2;
	    zone.y = y1;
	    zone.width = 1;
	    zone.height = y2 - y1;
		gdk_region_union_with_rect (other, &zone);
}
int f_detect (char *cascadeName, 
		char *fileName,
		FImageView *image_view)
{
	GdkRectangle zone;
 	cairo_t *ctx;
	GdkRegion *selection;
	GdkRegion *other = gdk_region_new ();
	int szWin = 0;
	int rowstride;
	unsigned char  *pixels;
	int n_channels;
	int i,x,y;
	GdkPixbuf *pb_sel;
	
	int pos_count = 0;
	int neg_count = 0;

	GdkRectangle recs[500];
	GdkPixbuf *pixbuf = image_view_get_pixbuf (IMAGE_VIEW(image_view));
	
	
	int width = gdk_pixbuf_get_width (pixbuf);
	int height = gdk_pixbuf_get_height (pixbuf);
	int width_orig = width;
	int height_orig = height;
	
	if(width>160)
	{
		
		pixbuf = gdk_pixbuf_scale_simple(pixbuf,160,120,GDK_INTERP_BILINEAR);
		width = gdk_pixbuf_get_width (pixbuf);
		height = gdk_pixbuf_get_height (pixbuf);
	}
	double xf = 1.0*width_orig/width;
	double yf = 1.0*height_orig/height;
rowstride = gdk_pixbuf_get_rowstride (pixbuf);
	 			pixels = gdk_pixbuf_get_pixels (pixbuf);
				n_channels = gdk_pixbuf_get_n_channels (pixbuf);
	
	int mindim = (width<height)?width:height;
	
	for (szWin = 30; szWin < mindim; szWin+=2) {
		for (x = 0; x < width-szWin; x+=5) {
			for (y = 0; y < height-szWin; y+=5) {
				
				// only the window !
				pb_sel = gdk_pixbuf_new_subpixbuf (pixbuf, x, y, szWin, szWin);
				pb_sel = gdk_pixbuf_scale_simple(pb_sel,25,25,GDK_INTERP_BILINEAR);
				rowstride = gdk_pixbuf_get_rowstride ( pb_sel );
	 			pixels = gdk_pixbuf_get_pixels (pb_sel);
				n_channels = gdk_pixbuf_get_n_channels (pb_sel);
				if(detect_ada(pixels, gdk_pixbuf_get_width(pb_sel),
							gdk_pixbuf_get_height(pb_sel), rowstride, 
							n_channels) && pos_count<500)
					{
							recs[pos_count].x=x*xf;
							recs[pos_count].y=y*yf;
							recs[pos_count].height=szWin*yf;
							recs[pos_count++].width =szWin*xf;
					}
							
							else neg_count++;
			}
		}
	}
	
	int overlapping=0;
	int eq=0;
	int in=0;
	int j;
	
	// the overlapping checking code is broken
	
	for(i=0; i<pos_count; i++)
	{
	/*	int overlaps = 0;
		for(j=0; j<pos_count; j++)
		{
			if (i==1) continue;
			
			
			 if(is_inner(recs[j],recs[i],xf,yf))
			{
				in++;
				overlaps++;
				break;
			}
			else if(is_equal(&recs[i],&recs[j],xf,yf))
			{
				eq++;
				overlaps++;
				break;
			}
			
		}
		if(!overlaps){*/
			draw_box(image_view,other,recs[i],xf,yf);
			
		//} else overlapping++;
	}
	printf("windows: accepted %d, rejected %d, overlapping %d\n",pos_count,neg_count,overlapping);
	//printf("eq %d in %d\n",eq,in);
		ctx = gdk_cairo_create (GTK_WIDGET (image_view)->window);
		cairo_set_source_rgba (ctx, .5, .2, .2, .7);
		gdk_cairo_region (ctx, other);
		cairo_fill (ctx);
		cairo_destroy (ctx);
	    gdk_region_destroy (other);

	if(!pos_count) return;
		
    return 0;
}


