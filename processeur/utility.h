#ifndef UTILITY_H
#define UTILITY_H

#include <stdint.h>

#include "control.h"

#define GET(c,i) ((c>>i)&1)

uint8_t invert_byte(uint8_t c);
uint16_t invert_word(uint16_t w);
uint32_t invert_dword(uint32_t dw);

uint8_t **init_matrix(int n, int m);
void free_matrix(uint8_t **m, int n);

void init_st(State *st);
void free_st(State *st);

int load_program(State *st, const char *filename);

void dump_registers(State *st);

#endif
