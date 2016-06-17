/*
  unsign: remove code signing from Mach-O and Universal Binary files.

  This program removes the LC_CODE_SIGNATURE load command and
  zeroes out the signature in the __LINKEDIT section.

  TODO: handle EOF errors better
  TODO: handle assumption failures with more grace

  Copyright (c) 2010

  Permission to use, copy, modify, and/or distribute this software for any
  purpose with or without fee is hereby granted, provided that the above
  copyright notice and this permission notice appear in all copies.

  The software is provided "as is" and the author disclaims all warranties
  with regard to this software including all implied warranties of
  merchantability and fitness. In no event shall the author be liable for
  any special, direct, indirect, or consequential damages or any damages
  whatsoever resulting from loss of use, data or profits, whether in an
  action of contract, negligence or other tortious action, arising out of
  or in connection with the use or performance of this software.
*/

#include "endian.h"

#include <assert.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>

#include <mach-o/fat.h>
#include <mach-o/loader.h>

#define BUF_SZ 4096

static void
expect(bool b, const char* s) {
        if (!b) {
                perror(s);
                abort();
        }
}

static size_t
fzero(size_t size, size_t count, FILE *stream) {
        for (size_t i = 0; i < count; i++) {
                for (size_t j = 0; j < size; j++) {
                        if (fputc(0, stream) == EOF) {
                                return i;
                        }
                }
        }
        return count;
}

static void
fcopy(size_t size, FILE *in, FILE *out, const char *infile, const char *outfile) {
        uint8_t buffer[512];
        while (size) {
                size_t to_copy = size;
                if(to_copy > sizeof(buffer)) {
                        to_copy = sizeof(buffer);
                }
                expect(fread(&buffer, 1, to_copy, in) == to_copy, infile);
                expect(fwrite(&buffer, 1, to_copy, out) == to_copy, outfile);
                size -= to_copy;
        }
}

static inline uintmax_t
to_align(uintmax_t n, uintmax_t a) {
        uintmax_t mask = a - 1;

        assert((a & mask) == 0);
        return (a - (n & mask)) & mask;
}

static void
align_file(FILE* f, const char *name, uintmax_t align) {
        off_t o = ftello(f);
        expect(o != -1, name);

        size_t to_write = to_align(o, align);
        expect(fzero(1, to_write, f) == to_write, name);
}

static void
macho_unsign(FILE *in, FILE *out, const char *infile, const char *outfile, off_t size) {
        off_t start = ftello(in);
        expect(start != -1, infile);

        uint8_t magicb[4];
        expect(fread(&magicb, sizeof(magicb), 1, in) == 1, infile);
        uint32_t magicbe = be32dec(&magicb);
        uint32_t magicle = le32dec(&magicb);

        bool big_endian, sixtyfourbits;
        if (magicbe == MH_MAGIC) {
                big_endian = true;
                sixtyfourbits = false;
        } else if (magicbe == MH_MAGIC_64) {
                big_endian = true;
                sixtyfourbits = true;
        } else if (magicle == MH_MAGIC) {
                big_endian = false;
                sixtyfourbits = false;
        } else if (magicle == MH_MAGIC_64) {
                big_endian = false;
                sixtyfourbits = true;
        } else {
                fprintf(stderr, "Unknown mach-o magic number %02x %02x %02x %02x\n",
                        magicb[0], magicb[1], magicb[2], magicb[3]);
                abort();
        }

        expect(fseeko(in, start, SEEK_SET) != -1, infile);

        uint32_t (*x32dec)(const void*) = big_endian ? be32dec : le32dec;
        void (*x32enc)(void*, uint32_t) = big_endian ? be32enc : le32enc;

        uint32_t ncmds;
        uint32_t sizeofcmds;
        if (sixtyfourbits) {
                struct mach_header_64 header;
                expect(fread(&header, sizeof(header), 1, in) == 1, infile);
                ncmds = x32dec(&header.ncmds);
                sizeofcmds = x32dec(&header.sizeofcmds);
                x32enc(&header.ncmds, ncmds - 1);
                x32enc(&header.sizeofcmds, sizeofcmds - sizeof(struct linkedit_data_command));
                expect(fwrite(&header, sizeof(header), 1, out) == 1, outfile);
        } else {
                struct mach_header header;
                expect(fread(&header, sizeof(header), 1, in) == 1, infile);
                ncmds = x32dec(&header.ncmds);
                sizeofcmds = x32dec(&header.sizeofcmds);
                x32enc(&header.ncmds, ncmds - 1);
                x32enc(&header.sizeofcmds, sizeofcmds - sizeof(struct linkedit_data_command));
                expect(fwrite(&header, sizeof(header), 1, out) == 1, outfile);
        }

        uint32_t dataoff = 0, datasize = 0;
        for (uint32_t i = 0; i < ncmds; i++) {
                off_t lc_start = ftello(in);
                expect(lc_start != -1, infile);

                struct load_command lc;
                expect(fread(&lc, sizeof(lc), 1, in) == 1, infile);
                uint32_t cmd = x32dec(&lc.cmd);
                uint32_t cmdsize = x32dec(&lc.cmdsize);

                expect(fseeko(in, lc_start, SEEK_SET) != -1, infile);
                if (cmd != LC_CODE_SIGNATURE) {
                        fcopy(cmdsize, in, out, infile, outfile);
                } else {
                        printf("    found LC_CODE_SIGNATURE\n");
                        assert(dataoff == 0);
                        struct linkedit_data_command lc_sig;
                        assert(cmdsize == sizeof(lc_sig));
                        expect(fread(&lc_sig, sizeof(lc_sig), 1, in) == 1, infile);
                        dataoff = x32dec(&lc_sig.dataoff);
                        assert(dataoff != 0);
                        datasize = x32dec(&lc_sig.datasize);
                }
        }
        assert(dataoff != 0);
        expect(fzero(sizeof(struct linkedit_data_command), 1, out) == 1, outfile);
        off_t after_lc = ftello(in);
        expect(after_lc != -1, infile);
        fcopy(dataoff - (after_lc - start), in, out, infile, outfile);
        expect(fzero(1, datasize, out) == datasize, outfile);
        expect(fseeko(in, datasize, SEEK_CUR) != -1, infile);
        off_t after_data = ftello(in);
        expect(after_data != -1, infile);
        fcopy(size - (after_data - start), in, out, infile, outfile);
}

static void
ub_unsign(FILE *in, FILE *out, const char *infile, const char *outfile, off_t size) {
        uint8_t magicb[4];
        expect(fread(&magicb, sizeof(magicb), 1, in) == 1, infile);
        if (be32dec(&magicb) != FAT_MAGIC) {
                expect(! fseeko(in, 0, SEEK_SET), infile);
                macho_unsign(in, out, infile, outfile, size);
                printf("not a fat binary\n");
                return;
        }

        uint8_t nfat_archb[4];
        expect(fread(&nfat_archb, sizeof(nfat_archb), 1, in) == 1, infile);

        expect(fwrite(&magicb, sizeof(magicb), 1, out) == 1, outfile);
        expect(fwrite(&nfat_archb, sizeof(nfat_archb), 1, out) == 1, outfile);

        uint32_t nfat_arch = be32dec(&nfat_archb);

        off_t outarcho = ftello(out);
        expect(outarcho != -1, outfile);

        expect(fzero(sizeof(struct fat_arch), nfat_arch, out) == nfat_arch, outfile);

        for (uint32_t i = 0; i < nfat_arch; i++) {
                printf("  processing fat architecture %d of %d\n", i+1, nfat_arch);
                struct fat_arch arch;
                expect(fread(&arch, sizeof(arch), 1, in) == 1, infile);
                off_t inarcho = ftello(in);
                expect(inarcho != -1, infile);

                uint32_t alignment = be32dec(&arch.align);
                assert(alignment < 32);
                alignment = 1 << alignment;
                align_file(out, outfile, alignment);

                expect(! fseeko(in, be32dec(&arch.offset), SEEK_SET), infile);

                off_t offset = ftello(out);

                macho_unsign(in, out, infile, outfile, be32dec(&arch.size));

                expect(! fseeko(in, inarcho, SEEK_SET), infile);

                off_t end = ftello(out);
                expect(end != -1, outfile);
                off_t size = end - offset;

                errno = ERANGE;
                uint32_t uoffset = offset;
                expect(uoffset == offset, "offset");
                uint32_t usize = size;
                expect(usize == size, "size");

                be32enc(&arch.offset, uoffset);
                be32enc(&arch.size, usize);

                off_t outo = ftello(out);
                expect(outo != -1, outfile);

                expect(! fseeko(out, outarcho, SEEK_SET), outfile);
                expect(fwrite(&arch, sizeof(arch), 1, out) == 1, outfile);
                outarcho = ftello(out);
                expect(outarcho != -1, outfile);
                expect(! fseeko(out, outo, SEEK_SET), outfile);
        }
}

const char *suffix = ".unsigned";

int
main(int argc, const char *const *argv) {
        if(argc < 2 || argc > 3) {
                puts("usage: unsign file [outfile]");
                return 1;
        }

        const char *infile = argv[1];
        char *outfile;
        if(argc > 2) {
                outfile = strdup(argv[2]);
                expect(outfile, "allocate");
        } else {
                outfile = malloc(strlen(infile) + strlen(suffix) + 1);
                expect(outfile, "allocate");
                sprintf(outfile, "%s%s", infile, suffix);
        }

        int infd = open(infile, O_RDONLY);
        expect(infd != -1, infile);
        struct stat stat;
        expect(fstat(infd, &stat) != -1, infile);


        FILE *in = fdopen(infd, "rb");
        expect(in, infile);
        printf("reading infile: %s\n", infile);

        FILE * outtmp = tmpfile();
        expect(outtmp, "unable to open temp file");

        ub_unsign(in, outtmp, infile, outfile, stat.st_size);

        fclose(in);

        int outfd = open(outfile, O_CREAT | O_TRUNC | O_WRONLY,
                         S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH /*755*/);
        expect(outfd != -1, outfile);
        FILE *outactual = fdopen(outfd, "wb");
        expect(outactual, outfile);

        unsigned char buf[BUF_SZ];

        fseek(outtmp, 0, SEEK_SET);
        do {
          size_t bytes_read = fread(buf, 1, BUF_SZ, outtmp);

          if (bytes_read > 0) {
            size_t bytes_written = fwrite(buf, 1, bytes_read, outactual);
            expect(bytes_written == bytes_read, "didnt write output file completely");
          }
        } while (!feof(outtmp));
        printf("wrote outfile: %s\n", outfile);
}
