#include <stdio.h>
#include <sys/mman.h> /* for mprotect */
#include <stdlib.h> /* for posix_memalign and free */
#include <unistd.h> /* for getpagesize */

#include "libguile/instructions.h" /* has an enum of all the VM instructions */
#include "libguile/snarf.h"
#include "libguile/objcodes.h"
#include "libguile/symbols.h"
#include "libguile/list.h"
#include "libguile/tags.h"
#include "libguile/strings.h" /* for scm_from_locale_string, for the init function */
#include "libguile/struct.h"
#include "libguile/numbers.h"

#include "libguile/vm-jit.h" /* defines vm-jit-return. */

#include <jit/jit.h>
#include <jit/jit-type.h>

static jit_context_t context = (jit_context_t) NULL;
static jit_type_t signature = NULL;

/* jit_objcode: this procedure either JITs the given object code, and
 * returns a pointer to an scm_jit_code object with the results, or
 * returns SCM_BOOL_F if it couldn't jit the code. this will most likely
 * occur if the jitter hits an object code that it doesn't know how to
 * translate. */
jitf jit_objcode (struct scm_objcode *objcode)
{
  scm_t_uint32 objcodelen;
  scm_t_uint8 *objcodep;
  jit_function_t function;
  jit_value_t ipp, spp, fpp, ip, sp, fp, ipup, spup;

  if ((context == NULL) ||
      (signature == NULL))
    goto abandon_jitting;

  jit_context_build_start (context);

  function = jit_function_create (context, signature);
  objcodelen = objcode->len;

  /* go ahead and load the three arguments into jit_values. It might
     happen that some jitted function is so simple that we wouldn't need
     to make all of these into values, in which case this would be a
     waste of effort, but that seems like such an unlikely case that I'm
     not going to optimize for it right now. */
  ipp = jit_value_get_param (function, 0); /* ipp = "instruction pointer
                                              pointer" */
  spp = jit_value_get_param (function, 1);
  fpp = jit_value_get_param (function, 2);

  ip = jit_insn_load_relative (function, ipp, 0, jit_type_void_ptr);
  sp = jit_insn_load_relative (function, spp, 0, jit_type_void_ptr);
  fp = jit_insn_load_relative (function, fpp, 0, jit_type_void_ptr);

  /* ipup is the constant value one must increment ip by to move one
     instruction further. */
  ipup = jit_value_create_nint_constant (function, jit_type_void_ptr,
                                         sizeof (scm_t_uint8));
  /* spup is the same, but to move sp one stack element. */
  spup = jit_value_create_nint_constant (function,
                                               jit_type_void_ptr,
                                               sizeof (SCM *));

  /* and now, JIT the objcode, one instruction at a time. */

  /* inside this for loop, ip, sp and fp are always temporary values
     containing the correct Guile VM ip, sp and fp registers. However,
     ipp, spp and fpp are not correct, and are not updated until after
     the for loop. */

  /* printf("ops: "); */
  for (objcodep = SCM_C_OBJCODE_BASE (objcode);
       objcodep - SCM_C_OBJCODE_BASE (objcode) < objcodelen;
       objcodep++)
    {
      switch ((enum scm_opcode)*objcodep) {
      case scm_op_nop:
        /* printf ("nop "); */
        break; /* the easiest opcode to implement. */
      case scm_op_assert_nargs_ee:
        /* printf ("nargs_ee "); */
        /* The function that implements this in vm-i-sys.c is in ** comments */
        {
          jit_value_t n, tmp1;
          jit_label_t good_path = jit_label_undefined;
          int n_val;

          /**  n = FETCH () << 8 **/
          /** n += FETCH (); **/
          /* because the FETCHes only take data from the instructions,
             which are constant, we can do them right here. */
          objcodep++;
          n_val = *objcodep;
          n_val <<= 8;
          ip = jit_insn_add (function, ip, ipup);
          objcodep++;
          n_val += *objcodep;
          ip = jit_insn_add (function, ip, ipup);
          n = jit_value_create_nint_constant (function, jit_type_int, n_val);

          /** if (sp = (fp - 1) != n) **/
          sp = jit_insn_sub (function, fp, spup);
          tmp1 = jit_insn_eq (function, sp, n);

          /* here is the label scheme: the instruction to return a wrong
             number of arguments error is in the instruction stream
             right after this. If, however, the number of instructions
             is correct, we will jump over that instruction using the
             label 'good_path' */
          jit_insn_branch_if (function, tmp1, &good_path);
          /** goto vm_error_wrong_num_args **/
          /* restore the ip, sp and fp pointers, and return. */
          jit_insn_store_relative (function, ipp, 0, ip);
          jit_insn_store_relative (function, spp, 0, sp);
          jit_insn_store_relative (function, fpp, 0, fp);
          jit_insn_return
            (function,
             jit_value_create_nint_constant (function, jit_type_int,
                                             jit_return_wrong_num_args));
          jit_insn_label (function, &good_path);
          break;
        }
      case scm_op_assert_nargs_ee_locals:
        /**   scm_t_ptrdiff n;
              SCM *old_sp;

              * nargs = n & 0x7, nlocs = nargs + (n >> 3) *
              n = FETCH ();

              if (SCM_UNLIKELY (sp - (fp - 1) != (n & 0x7)))
              goto vm_error_wrong_num_args;

              old_sp = sp;
              sp += (n >> 3);
              CHECK_OVERFLOW ();
              while (old_sp < sp)
              *++old_sp = SCM_UNDEFINED; **/
        /* printf ("nargs_ee/locals "); */
        {
          jit_value_t tmp1, tmp2, tmp3, val_scm_undefined;
          jit_label_t good_path = jit_label_undefined;
          int n_val, count;

          objcodep++; ip = jit_insn_add (function, ip, ipup);
          n_val = *objcodep;

          tmp1 = jit_insn_sub (function, fp, spup);

          tmp2 = jit_insn_sub (function, sp, tmp1);

          tmp3 = jit_insn_eq (function, tmp2,
                              jit_value_create_nint_constant (function,
                                                              jit_type_void_ptr,
                                                              n_val&0x7));

          /* here is the label scheme: the instruction to return a wrong
             number of arguments error is in the instruction stream
             right after this. If, however, the number of instructions
             is correct, we will jump over that instruction using the
             label 'good_path' */
          jit_insn_branch_if (function, tmp3, &good_path);
          /** goto vm_error_wrong_num_args **/
          /* restore the ip, sp and fp pointers, and return. */
          jit_insn_store_relative (function, ipp, 0, ip);
          jit_insn_store_relative (function, spp, 0, sp);
          jit_insn_store_relative (function, fpp, 0, fp);
          jit_insn_return
            (function,
             jit_value_create_nint_constant (function, jit_type_int,
                                             jit_return_wrong_num_args));
          jit_insn_label (function, &good_path);

          /* now I'm going to unroll a loop, not for performance, but
             because it makes this code simpler. */
          val_scm_undefined =
            jit_value_create_nint_constant (function, jit_type_void_ptr,
                                            (jit_nint)SCM_UNDEFINED);
          for (count = 0;
               count < (n_val >> 3);
               count++)
            {
              sp = jit_insn_add (function, sp, spup);
              jit_insn_store_relative (function, sp, 0, val_scm_undefined);
            }
          break;
        }

      case scm_op_make_int8:
        /** PUSH (SCM_I_MAKINUM ((signed char) FETCH ()));  **/
        /** where FETCH () := (*ip++)
            SCM_I_MAKINUM (x) := (SCM_PACK ((((scm_t_signed_bits) (x)) << 2)
                                            + scm_tc2_int))
            SCM_PACK (x) := x
            PUSH (x) := sp++; CHECK_OVERFLOW(); *sp = x;
            CHECK_OVERFLOW() := if (sp >= stack_limit)
                                  goto vm_error_stack_overflow;
        **/
        /* this version will not include a stack overflow check, for
           convenience. */
        /* printf ("make_int8 "); */
        {
          jit_value_t tmp1;
          int i_val;
          SCM s_val;
          
          /* the fetch */
          objcodep++;
          i_val = (int)*objcodep;
          ip = jit_insn_add (function, ip, ipup);
          /* the processing */
          s_val = SCM_PACK ((((scm_t_signed_bits) (i_val)) << 2) + scm_tc2_int);
          /* the value as JIT constant */
          tmp1 = jit_value_create_nint_constant(function,
                                                jit_type_int,
                                                (jit_nint)s_val);
          /* the push */
          sp = jit_insn_add (function, sp, spup);
          jit_insn_store_relative (function, sp, 0, tmp1);
          
          break;
        }
      case scm_op_make_int8_0:
        /** PUSH (SCM_INUM0); **/
        /* printf ("make_int8:0 "); */
        sp = jit_insn_add (function, sp, spup);
        jit_insn_store_relative
          (function, sp, 0,
           jit_value_create_nint_constant (function,
                                           jit_type_void_ptr,
                                           SCM_INUM0));
        break;
      case scm_op_return:
        /* printf ("return "); */
        /* there's nothing to this because the regular VM return
           instruction inspects the return value to be the first value
           on the VM stack, so all we do is return a marker that we've
           hit a return and jump to the regular return label */
        /* after everything, put ip, sp and fp back in their places to
           return to the calling function. */
        jit_insn_store_relative (function, ipp, 0, ip);
        jit_insn_store_relative (function, spp, 0, sp);
        jit_insn_store_relative (function, fpp, 0, fp);
        ip = jit_insn_add (function, ip, ipup); /* because we're never
                                                  going to hit the add
                                                  function after the
                                                  return. */
        jit_insn_return (function,
                         jit_value_create_nint_constant (function,
                                                         jit_type_int,
                                                         jit_return_return));
        break;
      default:
        goto abandon_jitting;
      }
      ip = jit_insn_add (function, ip, ipup);
    }

  /* printf ("\n"); */

  {
    int retval;
    retval = jit_function_compile (function);
    if (retval == 0)
      goto abandon_jitting;
  }

  jit_context_build_end (context);

  /* printf ("Successfully JITed something!\n"); */

  return (jitf) function;

 abandon_jitting:
  if ( context != NULL )
    jit_context_build_end (context);
  if ( function != NULL )
    jit_function_abandon (function);
  /* printf ("bail on %d\n", *objcodep); */
  return (jitf) SCM_BOOL_F;
}

enum jit_return_t call_jit_function (jitf func, scm_t_uint8 **ipp,
                                     SCM **spp, SCM **fpp)
{
  enum jit_return_t retval;
  void *args[] = {&ipp, &spp, &fpp};

  /* printf ("entering jit function. sp: %p, fp: %p\n", *spp, *fpp); */
  jit_function_apply (func, args, &retval);
  /* printf ("exited jit function. sp: %p, fp: %p, return: %d\n", *spp,
            *fpp, retval); */

  return retval;
}

void scm_init_jit (void)
{
  jit_type_t ip_type, sp_type, fp_type, params[3], ret_type;

  jit_init ();
  context = jit_context_create ();

  if (context == NULL)
    goto fail_init;
    
  ip_type = jit_type_create_pointer
    (jit_type_create_pointer (jit_type_ubyte, 0),
     1);
  sp_type = jit_type_create_pointer
    (jit_type_create_pointer (jit_type_void_ptr, 0),
     1);
  fp_type = sp_type;

  params[0] = ip_type;
  params[1] = sp_type;
  params[2] = fp_type;

  ret_type = jit_type_ubyte;

  if ((ip_type == NULL) || /* we only need to consider the ones we create */
      (sp_type == NULL)) {
    ip_type = NULL; /* because this is the flag for if these types exist. */
    goto fail_init;
  }

  signature = jit_type_create_signature
    (jit_abi_cdecl, /* native C calling conventions */
     ret_type,
     params,
     3, /* there are 3 params */
     1); /* yes, increment the reference counts for the types we use */

  if (signature == NULL)
    goto fail_init;

  return;
    
 fail_init:
  context = NULL;
  signature = NULL;
  
  return;
}
