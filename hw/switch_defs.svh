`ifndef __SWITCH_DEFS_SVH__
`define __SWITCH_DEFS_SVH__

`define WORD_SIZE 8
`define BLOCK_SIZE 32
`define META_OUT_SIZE 32
`define META_SRC_DEST_WIDTH 2
`define META_LENGTH_WIDTH 6
`define META_TIME_STAMP_WIDTH 22

typedef enum logic [4:0] {
	IDLE,
	RECEIVE_LENGTH_DEST_MAC_FST,
	RECEIVE_LENGTH_DEST_MAC_SND,
	RECEIVE_SRC_MAC_FST,
	RECEIVE_SRC_MAC_SND,
	RECEIVE_TIME_STAMPS_FST,
	RECEIVE_TIME_STAMPS_SND,
  	RECEIVE_PAYLOAD,
	DONE
} PACKET_METADATA_STATE;

typedef struct packed {
	logic [`META_SRC_DEST_WIDTH-1:0] dest;
	logic [`META_SRC_DEST_WIDTH-1:0] src;
	logic [`META_LENGTH_WIDTH-1:0] len;
	logic [`META_TIME_STAMP_WIDTH-1:0] t_delta;
} metadata_o;

`endif // __SWITCH_DEFS_SVH__