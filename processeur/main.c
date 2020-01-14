#include <stdio.h>
#include <stdlib.h>

#include "control.h"

typedef unsigned char uchar;

#define GET(c,i) ((c>>i)&1)

uchar invert_byte(uchar c)
{
	return GET(c,7) | (GET(c,6)<<1) | (GET(c,5)<<2) | (GET(c,4)<<3) | (GET(c,3)<<4) | (GET(c,2)<<5) | (GET(c,1)<<6) | (GET(c,0)<<7);
}

uchar **init_matrix(int n, int m)
{
	uchar **res = malloc(sizeof(uchar*)*n);
	for (int i = 0 ; i < n ; i++)
		res[i] = calloc(m,sizeof(uchar));
	return res;
}

void free_matrix(uchar **m, int n)
{
	for (int i = 0 ; i < n ; i++)
		free(m[i]);
	free(m);
}

void init_st(State *st)
{
  st->mem_rs1_data = init_matrix(32,4); // Intended size : 32 x 4
  st->mem_mem_rd_data = init_matrix(16384,4); // Intended size : 16384 x 4
  st->mem_ins = init_matrix(65536,4); // Intended size : 65536 x 4
  st->mem_rs2_data = init_matrix(32,4); // Intended size : 32 x 4
  st->mem_pc = init_matrix(2,2); // Intended size : 2 x 2
}

void free_st(State *st)
{
	free_matrix(st->mem_rs1_data, 32);
	free_matrix(st->mem_rs2_data, 32);
	free_matrix(st->mem_mem_rd_data, 16384);
	free_matrix(st->mem_ins, 65536);
	free_matrix(st->mem_pc, 2);
}

int load_program(State *st, const char *filename)
{
	FILE *prog = fopen(filename, "rb");

	int c;
	int n = 0, ofs = 0;
	while ((c = getc(prog)) != EOF)
	{
		st->mem_ins[((int) invert_byte((uchar) (4*n)))<<8][ofs] = invert_byte((uchar) c);
		ofs++;
		if (ofs > 3)
		{
			ofs = 0;
			n++;
		}
	}

	fclose(prog);
	return n;
}

void dump_registers(State *st)
{
	for (int i = 0; i < 32 ; i++)
	{
		int val = 0;
		int r = invert_byte((uchar)i)>>3;
		for (int j = 0 ; j < 4 ; j++)
			val = (val<<8) + invert_byte(st->mem_rs1_data[r][j]);
		printf("Value of r%d : %d\n", i, val);
	}

	int val = 0;
	for (int j = 0 ; j < 2 ; j++)
		val = (val<<8) + invert_byte(st->mem_pc[0][j]);
	printf("Value of pc : %d\n", val);
}

int main(int argc, char *argv)
{
	State st;
	init_st(&st);
	int n = load_program(&st,"program.bin");

	printf("Nb of instructions : %d\n", n);

	for (int i = 0 ; i < n ; i++)
		compute_cycle(&st);

	dump_registers(&st);
	free_st(&st);

	return 0;
}


