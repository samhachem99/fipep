module top_module ();
	reg clk=0;
	always #5 clk = ~clk;  // Create clock with period=10
	initial `probe_start;   // Start the timing diagram

	`probe(clk);        // Probe signal "clk"
	integer i;
	// A testbench
	reg reset=0;
    `probe(reset);
    reg [15:0][15:0] dig_data;
    
	initial begin
        for (i = 0; i < 16; i++) begin
            dig_data[i] = 0;
        end
        #5 reset = 1;
        #10 reset = 0;
        dig_data[1] = 26801;
		#1000 $finish;            // Quit the simulation
	end

    speed FIPEP(.clk, .rst(reset), .dig_data);

endmodule

module FIPEP(input clk, input rst, input [15:0][15:0] dig_data );
    // Parameters
    parameter PEAKTHRESH	= 26800;
    parameter NUM_PULSES	= 400;
    parameter NUM_BINS		= 40;

    // Counters
    reg [13:0] sample_ctr;  // Seen 16*sample_ctr number of samples
    reg [17:0] pixel_ctr;   // 256x256
    reg [5:0] bin_ctr;

    // Store the samples from the last digitizer readout
    reg [15:0] pst_values [1:0];

    // Double Buffer histogram 
    reg [8:0] db_histogram [NUM_BINS-1:0][1:0];
    reg db_hist_w_ptr;

    integer i;          // Loop variable
    integer j;
    always @(posedge clk) begin
        if (rst) begin
            // Reset
    		sample_ctr <= 0;
            pixel_ctr <= 0;
            bin_ctr <= 0;
            pst_values[0] <= 0;
            pst_values[1] <= 0;

            db_hist_w_ptr <= 0;
            // Clear the histograms
            for (i = 0; i < 2; i++) begin
            	for (j = 0; j < 40; j++) begin
                    db_histogram[j][i] <= 0;
            	end
            end
        end
        else begin
        	// Normal operation
            // Increment Sample Counter and check if we're at a new pixel
            // There are 16000 samples per pixel (or 1000 16-block samples)
            if (sample_ctr >= 15999) begin
                //if (sample_ctr >= 159) begin // This line is for simulation testing
                // New pixel so we need to reset our sample counters
            	sample_ctr <= 0;
                pixel_ctr <= pixel_ctr + 1;
                bin_ctr <= 0;
                db_hist_w_ptr <= ~db_hist_w_ptr;
            end 
            else begin
            	sample_ctr <= sample_ctr + 16;

            	// Track Which 16-Bins we are seeing
            	if (bin_ctr >= 40) begin
            		bin_ctr <= bin_ctr-24;	// +16-40
            	end else begin
            		bin_ctr <= bin_ctr+16;
            	end
            end

            // Clear read buffer before passing it back to the CPU
            if (sample_ctr == 15984) begin
                for (j = 0; j < 40; j++) begin
                    db_histogram[j][~db_hist_w_ptr] <= 0;
            	end
            end
            // Update Past Values
            pst_values[0] <= dig_data[14];
            pst_values[1] <= dig_data[15];

            // Check if each sample is a peak
            for (i = 1; i < 17; i++) begin
            	// Inverted Peak detection (because PMT readout is negative)
                // It is unclear what the paper is doing, so this is temporary
                if (data_18[i] >= PEAKTHRESH & data_18[i] >= data_18[i-1] & data_18[i] >= data_18[i+1]) begin
                    // SPEED Peak increment
                    // Avoid Modulo by utilizing a bin counter
                    if (bin_ctr+i-2 < 40) begin
                        db_histogram[bin_ctr+i-2][db_hist_w_ptr] <= db_histogram[bin_ctr+i-2][db_hist_w_ptr]+1;
                	end else begin
                        db_histogram[bin_ctr+i-40-2][db_hist_w_ptr] <= db_histogram[bin_ctr+i-40-2][db_hist_w_ptr]+1;
                	end
                end
            end
        end
    end

    // Set up the values we will be finding peaks from
    reg [15:0] data_18 [17:0];    // Includes past values into data
    always @(*) begin
        data_18[0] = pst_values[0];
        data_18[1] = pst_values[1];
        for (i = 0; i < 16; i++) begin 
            data_18[i+2] = dig_data[i];
        end
    end
	
    
    `probe(db_histogram[0][0]);
    `probe(db_histogram[1][0]);
    `probe(db_histogram[2][0]);
    `probe(db_histogram[3][0]);
    `probe(db_histogram[4][0]);
    `probe(db_histogram[5][0]);
    `probe(db_histogram[6][0]);
    `probe(db_histogram[7][0]);
    `probe(db_histogram[8][0]);
    `probe(db_histogram[9][0]);
    `probe(db_histogram[10][0]);
    `probe(db_histogram[11][0]);
    `probe(db_histogram[12][0]);
    `probe(db_histogram[13][0]);
    `probe(db_histogram[14][0]);
    `probe(db_histogram[15][0]);
    `probe(db_histogram[16][0]);
    `probe(db_histogram[17][0]);
    `probe(db_histogram[18][0]);
    `probe(db_histogram[19][0]);
    `probe(db_histogram[20][0]);
    
    
endmodule
 

