#ifndef _SCM_VM_JIT_H_
#define _SCM_VM_JIT_H_

#include "_scm.h"

/* jit_return_t is the return value of jitted functions. */
/* it must be a set of integer values that can fit into a byte (or else
   you must change the function's signature in vm-jit.c */

enum jit_return_t {
  jit_return_return = 0,
  jit_return_wrong_num_args
};

typedef void *jitf;

jitf jit_objcode (struct scm_objcode *objcode);
enum jit_return_t call_jit_function (jitf function, scm_t_uint8 **ip,
                                     SCM **sp, SCM **fp);
void scm_init_jit (void);

#endif /* not _SCM_VM_JIT_H_ */
