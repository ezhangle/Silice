// -------------------------

// Text buffer
import('../common/text_buffer.v')

// VGA driver
// SL 2019-10
// -------------------------

algorithm vga(
  output! uint1  vga_hs,
  output! uint1  vga_vs,
  output! uint1  active,
  output! uint1  vblank,
  output! uint10 vga_x,
  output! uint10 vga_y
) <autorun> {

  uint10 H_FRT_PORCH = 16;
  uint10 H_SYNCH     = 96;
  uint10 H_BCK_PORCH = 48;
  uint10 H_RES       = 640;

  uint10 V_FRT_PORCH = 10;
  uint10 V_SYNCH     = 2;
  uint10 V_BCK_PORCH = 33;
  uint10 V_RES       = 480;

  uint10 HS_START = 0;
  uint10 HS_END   = 0;
  uint10 HA_START = 0;
  uint10 H_END    = 0;

  uint10 VS_START = 0;
  uint10 VS_END   = 0;
  uint10 VA_START = 0;
  uint10 V_END    = 0;

  uint10 xcount = 0;
  uint10 ycount = 0;

  HS_START := H_FRT_PORCH;
  HS_END   := H_FRT_PORCH + H_SYNCH;
  HA_START := H_FRT_PORCH + H_SYNCH + H_BCK_PORCH;
  H_END    := H_FRT_PORCH + H_SYNCH + H_BCK_PORCH + H_RES;

  VS_START := V_FRT_PORCH;
  VS_END   := V_FRT_PORCH + V_SYNCH;
  VA_START := V_FRT_PORCH + V_SYNCH + V_BCK_PORCH;
  V_END    := V_FRT_PORCH + V_SYNCH + V_BCK_PORCH + V_RES;

  vga_hs := ~((xcount >= HS_START && xcount < HS_END));
  vga_vs := ~((ycount >= VS_START && ycount < VS_END));

  active := (xcount >= HA_START && xcount < H_END)
         && (ycount >= VA_START && ycount < V_END);
  vblank := (ycount < VA_START);

  xcount = H_END;
  ycount = V_END;

  while (1) {

    if (active) {
      vga_x = xcount - HA_START;
      vga_y = ycount - VA_START;
    }

    if (xcount == H_END-1) {
      xcount = 0;
      if (ycount == V_END-1) {
        ycount = 0;
      } else {
        ycount = ycount + 1;
	  }
    } else {
      xcount = xcount + 1;
	}
  }

}

// -------------------------


// -------------------------

algorithm text_display(
  input   uint10 pix_x,
  input   uint10 pix_y,
  input   uint1  pix_active,
  input   uint1  pix_vblank,
  output! uint4  pix_red,
  output! uint4  pix_green,
  output! uint4  pix_blue
) <autorun> {

// Text buffer

uint14 txtaddr   = 0;
uint6  txtdata_r = 0;
uint6  txtdata_w = 0;
uint1  txtwrite  = 0;

text_buffer txtbuf (
  clk     <: clock,
  addr    <: txtaddr,
  wdata   <: txtdata_w,
  rdata   :> txtdata_r,
  wenable <: txtwrite
);

  // ---------- font
  
uint1 letters[2432] = {
  //[0] 0
  0,0,1,1,1,1,0,0,
  0,1,0,0,0,1,1,0,
  0,1,0,0,1,0,1,0,
  0,1,0,0,1,0,1,0,
  0,1,0,1,0,0,1,0,
  0,1,0,1,0,0,1,0,
  0,1,1,0,0,0,1,0,
  0,0,1,1,1,1,0,0,
  // 1
  0,0,0,0,1,0,0,0,
  0,0,0,1,1,0,0,0,
  0,0,1,0,1,0,0,0,
  0,0,0,0,1,0,0,0,
  0,0,0,0,1,0,0,0,
  0,0,0,0,1,0,0,0,
  0,0,0,0,1,0,0,0,
  0,0,0,1,1,1,0,0,
  // 2
  0,0,1,1,1,1,0,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,0,0,0,1,1,1,0,
  0,0,0,1,0,0,0,0,
  0,0,1,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,1,1,1,1,0,0,
  // 3
  0,0,1,1,1,1,0,0,
  0,1,0,0,0,0,1,0,
  0,0,0,0,0,0,1,0,
  0,0,0,1,1,1,0,0,
  0,0,0,0,0,1,0,0,
  0,0,0,0,0,0,1,0,
  0,0,0,0,0,0,1,0,
  0,1,1,1,1,1,0,0,
  // 4
  0,0,0,0,0,1,0,0,
  0,0,0,0,1,1,0,0,
  0,0,0,1,0,1,0,0,
  0,0,1,0,0,1,0,0,
  0,1,1,1,1,1,1,0,
  0,0,0,0,0,1,0,0,
  0,0,0,0,0,1,0,0,
  0,0,0,0,0,1,0,0,
  // 5
  0,1,1,1,1,1,1,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,1,1,1,1,0,0,
  0,0,0,0,0,0,1,0,
  0,0,0,0,0,0,1,0,
  0,1,1,1,1,1,0,0,
  // 6
  0,0,0,0,0,1,1,0,
  0,0,0,0,1,0,0,0,
  0,0,0,1,0,0,0,0,
  0,0,1,0,0,0,0,0,
  0,1,1,1,1,1,0,0,
  1,0,0,0,0,0,1,0,
  1,0,0,0,0,0,1,0,
  0,1,1,1,1,1,0,0,
  // 7
  0,1,1,1,1,1,0,0,
  0,0,0,0,0,0,1,0,
  0,0,0,0,0,1,0,0,
  0,0,0,0,0,1,0,0,
  0,0,0,0,0,1,0,0,
  0,0,0,0,1,0,0,0,
  0,0,0,0,1,0,0,0,
  0,0,0,0,1,0,0,0,
  // 8
  0,1,1,1,1,1,0,0,
  1,0,0,0,0,0,1,0,
  1,0,0,0,0,0,1,0,
  1,0,0,0,0,0,1,0,
  0,1,1,1,1,1,0,0,
  1,0,0,0,0,0,1,0,
  1,0,0,0,0,0,1,0,
  0,1,1,1,1,1,0,0,
  // [9] 9
  0,1,1,1,1,1,0,0,
  1,0,0,0,0,0,1,0,
  1,0,0,0,0,0,1,0,
  0,1,1,1,1,1,0,0,
  0,0,0,0,0,1,0,0,
  0,0,0,0,1,0,0,0,
  0,0,0,1,0,0,0,0,
  0,0,1,0,0,0,0,0,
  //[10] a
  0,0,0,1,1,0,0,0,
  0,0,1,0,0,1,0,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,1,1,1,1,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  // b
  0,1,1,1,1,0,0,0,
  0,1,0,0,0,1,0,0,
  0,1,0,0,0,1,0,0,
  0,1,0,0,1,0,0,0,
  0,1,1,1,1,1,0,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,1,1,1,1,0,0,
  // c
  0,0,0,1,1,1,0,0,
  0,0,1,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,0,1,0,0,0,0,0,
  0,0,0,1,1,1,1,0,
  // d
  0,1,1,1,1,0,0,0,
  0,1,0,0,0,1,0,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,1,1,0,
  0,1,1,1,1,0,0,0,
  // e
  0,1,1,1,1,1,0,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,1,1,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,1,1,1,1,1,0,
  // f
  0,1,1,1,1,1,1,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,1,1,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  // g
  0,0,0,1,1,1,0,0,
  0,0,1,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,1,1,1,0,
  0,1,0,0,0,0,1,0,
  0,0,1,0,0,0,1,0,
  0,0,0,1,1,1,1,0,
  // h
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,1,1,1,1,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  // i
  0,0,0,1,1,0,0,0,
  0,0,0,1,1,0,0,0,
  0,0,0,0,0,0,0,0,
  0,0,0,0,1,0,0,0,
  0,0,0,0,1,0,0,0,
  0,0,0,0,1,0,0,0,
  0,0,0,0,1,0,0,0,
  0,0,0,0,1,0,0,0,
  // j
  0,0,0,0,1,1,0,0,
  0,0,0,0,1,1,0,0,
  0,0,0,0,0,0,0,0,
  0,0,0,0,0,1,0,0,
  0,0,0,0,0,1,0,0,
  0,0,0,0,0,1,0,0,
  0,1,0,0,0,1,0,0,
  0,0,1,1,1,0,0,0,
  // k
  0,1,0,0,1,0,0,0,
  0,1,0,0,1,0,0,0,
  0,1,0,0,1,0,0,0,
  0,1,0,1,0,0,0,0,
  0,1,1,1,0,0,0,0,
  0,1,0,0,1,0,0,0,
  0,1,0,0,0,1,0,0,
  0,1,0,0,0,1,0,0,
  // l
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,0,1,1,1,1,0,0,
  // m
  0,0,0,0,0,0,0,0,
  0,1,1,0,0,1,1,0,
  1,0,0,1,1,0,0,1,
  1,0,0,0,0,0,0,1,
  1,0,0,0,0,0,0,1,
  1,0,0,0,0,0,0,1,
  1,0,0,0,0,0,0,1,
  1,0,0,0,0,0,0,1,
  // n
  0,1,0,0,0,0,1,0,
  0,1,1,0,0,0,1,0,
  0,1,0,1,0,0,1,0,
  0,1,0,0,1,0,1,0,
  0,1,0,0,0,1,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  // o
  0,0,1,1,1,1,0,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,0,1,1,1,1,0,0,
  // p
  0,0,1,1,1,1,0,0,
  0,0,1,0,0,0,1,0,
  0,0,1,0,0,0,1,0,
  0,0,1,0,0,0,1,0,
  0,0,1,1,1,1,1,0,
  0,0,1,0,0,0,0,0,
  0,0,1,0,0,0,0,0,
  0,0,1,0,0,0,0,0,
  // q
  0,0,1,1,1,1,0,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,1,0,0,1,0,
  0,0,1,0,0,0,1,0,
  0,1,0,1,1,1,0,0,
  // r
  0,1,1,1,1,1,0,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,1,1,1,1,0,0,
  0,1,0,0,0,1,0,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,0,1,
  // s
  0,0,1,1,1,1,0,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,0,1,1,1,1,0,0,
  0,0,0,0,0,0,1,0,
  0,0,0,0,0,0,1,0,
  0,1,1,1,1,1,0,0,
  // t
  1,1,1,1,1,1,1,0,
  0,0,0,1,0,0,0,0,
  0,0,0,1,0,0,0,0,
  0,0,0,1,0,0,0,0,
  0,0,0,1,0,0,0,0,
  0,0,0,1,0,0,0,0,
  0,0,0,1,0,0,0,0,
  0,0,0,1,0,0,0,0,
  // u
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,0,1,1,1,1,0,0,
  // v
  1,0,0,0,0,0,0,1,
  1,0,0,0,0,0,0,1,
  1,0,0,0,0,0,0,1,
  0,1,0,0,0,0,1,0,
  0,1,0,0,0,0,1,0,
  0,0,1,0,0,1,0,0,
  0,0,1,0,0,1,0,0,
  0,0,0,1,1,0,0,0,
  // w
  1,0,0,0,0,0,0,1,
  1,0,0,0,0,0,0,1,
  1,0,0,0,0,0,0,1,
  1,0,0,0,0,0,0,1,
  0,1,0,0,0,0,1,0,
  0,1,0,1,1,0,1,0,
  0,1,0,1,1,0,1,0,
  0,0,1,0,0,1,0,0,
  // x
  0,1,0,0,0,1,0,0,
  0,1,0,0,0,1,0,0,
  0,1,0,0,0,1,0,0,
  0,0,1,0,1,0,0,0,
  0,0,0,1,0,0,0,0,
  0,0,1,0,1,0,0,0,
  0,1,0,0,0,1,0,0,
  0,1,0,0,0,1,0,0,
  // y
  1,0,0,0,0,1,0,0,
  1,0,0,0,0,1,0,0,
  0,1,0,0,1,0,0,0,
  0,0,1,0,1,0,0,0,
  0,0,0,1,0,0,0,0,
  0,0,0,1,0,0,0,0,
  0,0,1,0,0,0,0,0,
  0,0,1,0,0,0,0,0,
  //[35] z
  0,1,1,1,1,1,1,0,
  0,0,0,0,0,0,1,0,
  0,0,0,0,0,1,0,0,
  0,0,0,0,1,0,0,0,
  0,0,0,1,0,0,0,0,
  0,0,1,0,0,0,0,0,
  0,1,0,0,0,0,0,0,
  0,1,1,1,1,1,1,0,
  //[36] <space>
  0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,
  //[37] <->
  0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,
  0,1,1,1,1,1,1,0,
  0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0
};

   
  // ---------- text display

  uint8  text_i   = 0;
  uint7  text_j   = 0;
  uint3  letter_i = 0;
  uint4  letter_j = 0;
  uint1  pixel    = 0;
  uint12 addr     = 0;

  uint16 next     = 0;

  uint11 str_x    = 10;
  uint10 str_y    = 10;

  int32   numb     = -32h1234;
  uint32  numb_tmp = 0;
  uint8   numb_cnt = 0;

  // ---------- string

  uint8  str[] = "HELLO WORLD FROM FPGA";
  uint8  tmp   = 0;
  uint8  step  = 0;

  // --------- print string
  subroutine print_string( 
	  reads      str,
	  reads      str_x,
	  reads      str_y,
	  writes     txtaddr,
	  writes     txtdata_w,
	  writes     txtwrite
	  ) {
    uint11 col  = 0;
    uint8  lttr = 0;

    while (str[col] != 0) {
      if (str[col] == 32) {
        lttr = 36;
      } else {
        lttr = str[col] - 55;
      }
      txtaddr   = col + str_x + str_y * 80;
      txtdata_w = lttr[0,6];
      txtwrite  = 1;
      col       = col + 1;
    }
	txtwrite = 0;
    return;
  }
  
  // by default r,g,b are set to zero
  pix_red   := 0;
  pix_green := 0;
  pix_blue  := 0;

  // fill buffer with spaces
  txtwrite  = 1;
  next      = 0;
  txtdata_w = 36; // data to write
  while (next < 4800) {
    txtaddr = next;     // address to write
    next    = next + 1; // next
  }
  txtwrite = 0;

  // ---------- show time!

  while (1) {

	  // prepare next frame
	  () <- print_string <- ();
	  str_y = str_y + 2;

      // wait until vblank is over
	  while (pix_vblank == 1) { }

	  // display frame
	  while (pix_vblank == 0) {

        pix_green = pix_y;

		if (letter_j < 8) {
		  letter_i = pix_x & 7;
		  addr     = letter_i + (letter_j << 3) + (txtdata_r << 6);
		  pixel    = letters[ addr ];
		  if (pixel == 1) {
			pix_red   = 15;
			pix_green = 15;
			pix_blue  = 15;
		  }
		}

		if (pix_active && (pix_x & 7) == 7) {   // end of letter
		  if (pix_x == 639) {  // end of line
	        // back to first column
        	text_i   = 0;
			// end of frame ?
			if (pix_y == 479) {
			  // yes
			  text_j   = 0;
			  letter_j = 0;
			} else {
  			  // no: next letter line
			  if (letter_j < 8) {
			    letter_j = letter_j + 1;
			  } else {
			    // next row
			    letter_j = 0;
			    text_j   = text_j + 1;
			  }
			}
		  } else {
		    text_i = text_i + 1;		  
		  }
		}

		txtaddr  = text_i + text_j * 80;
		
	  }

  }
}

// -------------------------

algorithm main(
  output! uint1 vga_clock,
  output! uint4 vga_r,
  output! uint4 vga_g,
  output! uint4 vga_b,
  output! uint1 vga_hs,
  output! uint1 vga_vs
) {

  uint1  active = 0;
  uint1  vblank = 0;
  uint10 pix_x  = 0;
  uint10 pix_y  = 0;

  vga vga_driver(
    vga_hs :> vga_hs,
	vga_vs :> vga_vs,
	active :> active,
	vblank :> vblank,
	vga_x  :> pix_x,
	vga_y  :> pix_y
  );

  text_display display(
	pix_x      <: pix_x,
	pix_y      <: pix_y,
	pix_active <: active,
	pix_vblank <: vblank,
	pix_red    :> vga_r,
	pix_green  :> vga_g,
	pix_blue   :> vga_b
  );


  uint8 frame  = 0;

  // vga clock is directly the input clock
  vga_clock := clock;

  // we count a number of frames and stop
  while (frame < 2) {
  
    while (vblank == 1) { }
	$display("vblank off");
    while (vblank == 0) { }
    $display("vblank on");
    frame = frame + 1;

  }
}


