#ifndef ENDIAN_H
#define ENDIAN_H

#include <stdint.h>

/* Alignment-agnostic encode/decode bytestream to/from little/big endian. */

uint16_t be16dec(const void *pp);
uint32_t be32dec(const void *pp);
uint64_t be64dec(const void *pp);

uint16_t le16dec(const void *pp);
uint32_t le32dec(const void *pp);
uint64_t le64dec(const void *pp);

void be16enc(void *pp, uint16_t u);
void be32enc(void *pp, uint32_t u);
void be64enc(void *pp, uint64_t u);

void le16enc(void *pp, uint16_t u);
void le32enc(void *pp, uint32_t u);
void le64enc(void *pp, uint64_t u);

#endif
