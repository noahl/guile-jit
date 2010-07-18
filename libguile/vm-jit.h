#ifndef _SCM_VM_JIT_H_
#define _SCM_VM_JIT_H_

#include "_scm.h"
#include "libguile/struct.h"

/* jitted code for a procedure will be stored as an array of pointers to the
 * blocks of the machine code. the generated machine code will expect this array
 * to be available (how?) when it is called, and all machine code branches will
 * indirect through this array. this is done to make the code relocatable: as
 * long as the block array points to the correct blocks, then the code can be
 * loaded anywhere in memory. this is important because it will allow us to
 * store the code to a .go file and mmap() it back into memory and have it still
 * work, which will allow fast startups. if we're storing code for a procedure,
 * the first pointer in the block array will point to the procedure entry point.
 *
 * a block is a basic block of the object code. it's not really a basic block
 * from the JIT perspective, because all of the instructions are implemented as
 * calls to C functions.
 *
 * (one could also implement position-independent code by only using relative
 * branches, but it's not clear that GNU Lightning supports this, so I'll use
 * the table method.) */

typedef void (*jitf)(void *block_pointers, scm_t_uint8 **ip,
                     SCM **sp, SCM **fp);

/* the first block is number 1. */
#define SCM_C_JITCODE_BLOCK(block_pointers, n)                           \
  (*((block_pointers) + (n) - 1))
  /*  SCM_STRUCT_SLOT_REF(obj, n - 1) */
#define SCM_JITCODE_ENTER(obj, ip, sp, fp)                    \
  ((jitf)(SCM_C_JITCODE_BLOCK(obj, 1)))(SCM_C_JITCODE_BLOCK(obj, 1), &ip, &sp, &fp)

jitf *jit_objcode(struct scm_objcode *objcode);

void scm_init_jit (void);

#endif /* not _SCM_VM_JIT_H_ */
