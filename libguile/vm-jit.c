#include <stdio.h>
#include <sys/mman.h> /* for mprotect */
#include <stdlib.h> /* for posix_memalign */
#include <unistd.h> /* for getpagesize */

#include "libguile/instructions.h"
#include "libguile/snarf.h"
#include "libguile/objcodes.h"
#include "libguile/symbols.h"
#include "libguile/list.h"
#include "libguile/tags.h"
#include "libguile/strings.h" /* for scm_from_locale_string, for the init function */
#include "libguile/struct.h"
#include "libguile/numbers.h"

#include "libguile/vm-jit.h" /* defines struct scm_jit_code */
#include "libguile/lightning/lightning.h"

/* SCM jitcode_vtable = NULL; */

void my_print(char *msg)
{
  printf(msg);
}

/* jit_objcode: this procedure either JITs the given object code, and returns a
 * pointer to an scm_jit_code object with the results, or SCM_BOOL_F if it
 * couldn't jit the code. this will most likely occur if the jitter hits an
 * object code that it doesn't know how to translate. */
jitf *jit_objcode(struct scm_objcode *objcode)
{
  /* SCM code; */
  jitf code, *block_pointers;
  jit_insn *buffer, *end;
  int memalign_res, mprotect_res;

  if (objcode->len > 0) {
    /* this is too complicated for us to JIT! :-) */
    return SCM_BOOL_F;
  }
  /* else, the real content of this function ... */

  /* this is an absurd allocation strategy. It can be fixed once the JIT is working. */
  memalign_res = posix_memalign(&buffer, getpagesize(), getpagesize());
  if (memalign_res != 0) {
    perror("posix_memalign");
    return (jitf *)SCM_BOOL_F;
  }

  /* Make a test function */
  jit_set_ip(buffer);
  jit_prolog(3);
  /*
  jit_movi_p(JIT_R0, "JIT code called!\n");
  jit_prepare(1);
  jit_pusharg_p(JIT_R0);
  jit_finish(my_print);
  */
  jit_ret();

  end = (jit_insn *)jit_get_ip().ptr;
  jit_flush_code(buffer, end);

  /* although it is technically the identity, this cast should make the JIT code
   * play as nicely with the C type system as we can expect. */
  code = (jitf)buffer;
  block_pointers = scm_gc_malloc (sizeof (jitf *),
                                  "an array of pointers to machine code");
  if (block_pointers == NULL)
    return (jitf *)SCM_BOOL_F;

  *block_pointers = code;

  mprotect_res = mprotect (code, getpagesize(),
                           PROT_READ | PROT_WRITE | PROT_EXEC);
  if (mprotect_res != 0) {
    perror("mprotect");
    return (jitf *)SCM_BOOL_F;
  }

  return block_pointers;
}

void scm_init_jit (void)
{
  /* jitcode_vtable = scm_make_vtable (scm_from_locale_string("pO"), SCM_UNDEFINED); */
  
  return;
}
