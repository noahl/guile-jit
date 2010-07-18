#include <stdio.h>

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
#include "lightning.h"

/* SCM jitcode_vtable = NULL; */

/* jit_objcode: this procedure either JITs the given object code, and returns a
 * pointer to an scm_jit_code object with the results, or SCM_BOOL_F if it
 * couldn't jit the code. this will most likely occur if the jitter hits an
 * object code that it doesn't know how to translate. */
jitf *jit_objcode(struct scm_objcode *objcode)
{
  /* SCM code; */
  jitf *code;
  jit_insn *buffer, *end;

  buffer = scm_gc_calloc(32 * sizeof (jit_insn), "JIT instruction buffer");
  if (buffer == NULL)
    return (jitf *)SCM_BOOL_F;

  /* Make a test function */
  jit_set_ip(buffer);
  jit_prolog(3);
  jit_movi_p(JIT_R0, "JIT code called!\n");
  jit_prepare(1);
  jit_pusharg_p(JIT_R0);
  jit_finish(printf);
  jit_ret();

  end = (jit_insn *)jit_get_ip().ptr;
  jit_flush_code(buffer, end);

  /* Make the struct */
  /* code = scm_c_make_structv(jitcode_vtable, 1, 1, (scm_t_bits *)buffer); */
  code = scm_gc_malloc (sizeof (jitf *), "a table of pointers to machine code");
  if (code == NULL)
    return (jitf *)SCM_BOOL_F;
  
  *code = (jitf *)buffer;

  return code;
}

void scm_init_jit (void)
{
  /* jitcode_vtable = scm_make_vtable (scm_from_locale_string("pO"), SCM_UNDEFINED); */
  
  return;
}
